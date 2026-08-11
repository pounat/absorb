import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'update_policy.dart';

class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseNotes;
  final bool isPreRelease;
  final bool isDirectApk;
  final String? packageLabel;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    this.releaseNotes = '',
    this.isPreRelease = false,
    this.isDirectApk = true,
    this.packageLabel,
  });

  bool get hasUpdate =>
      compareUpdateVersions(latestVersion, currentVersion) > 0;
}

class UpdateCheckerService {
  static const _repo = 'pounat/absorb'; // Update this to your repo
  static const _checkInterval = Duration(hours: 12);
  static const _dismissedKey = 'update_dismissed_version';
  static const _lastCheckKey = 'update_last_check';
  static const _updateChannel = MethodChannel('com.absorb.update');

  static Future<String> currentInstalledVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    int? baseBuildNumber;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        baseBuildNumber =
            await _updateChannel.invokeMethod<int>('getBaseBuildNumber');
      } catch (error) {
        debugPrint('[UpdateChecker] Base build lookup failed: $error');
      }
    }
    return currentUpdateVersion(
      versionName: packageInfo.version,
      packageBuildNumber: packageInfo.buildNumber,
      baseBuildNumber: baseBuildNumber,
    );
  }

  /// Check for updates. Returns UpdateInfo if a newer version exists, null otherwise.
  /// Respects a 12-hour cooldown between checks and skips dismissed versions.
  /// When [includePreReleases] is true, pre-release/alpha builds are also considered.
  static Future<UpdateInfo?> check({bool force = false, bool includePreReleases = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cooldown check (skip if forced)
      if (!force) {
        final lastCheck = prefs.getInt(_lastCheckKey) ?? 0;
        final elapsed = DateTime.now().millisecondsSinceEpoch - lastCheck;
        if (elapsed < _checkInterval.inMilliseconds) return null;
      }

      await prefs.setInt(_lastCheckKey, DateTime.now().millisecondsSinceEpoch);

      Map<String, dynamic>? data;

      if (includePreReleases) {
        // Fetch all releases and pick the first (newest) one, which may be a pre-release
        final response = await http.get(
          Uri.parse('https://api.github.com/repos/$_repo/releases?per_page=5'),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ).timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) return null;
        final releases = jsonDecode(response.body) as List<dynamic>;
        if (releases.isEmpty) return null;
        data = releases.first as Map<String, dynamic>;
      } else {
        final response = await http.get(
          Uri.parse('https://api.github.com/repos/$_repo/releases/latest'),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ).timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) return null;
        data = jsonDecode(response.body) as Map<String, dynamic>;
      }

      final tagName = data['tag_name'] as String? ?? '';
      final body = data['body'] as String? ?? '';
      final assets = data['assets'] as List<dynamic>? ?? [];
      final isPreRelease = data['prerelease'] as bool? ?? false;

      final releaseAssets = <UpdateReleaseAsset>[];
      for (final rawAsset in assets) {
        if (rawAsset is! Map<String, dynamic>) continue;
        final name = rawAsset['name'] as String? ?? '';
        final url = rawAsset['browser_download_url'] as String? ?? '';
        if (name.isNotEmpty && url.isNotEmpty) {
          releaseAssets.add(UpdateReleaseAsset(name: name, downloadUrl: url));
        }
      }

      List<String> supportedAbis = const [];
      if (!kIsWeb && Platform.isAndroid) {
        try {
          supportedAbis =
              (await DeviceInfoPlugin().androidInfo).supportedAbis;
        } catch (error) {
          debugPrint('[UpdateChecker] ABI detection failed: $error');
        }
      }
      final selectedAsset = selectAndroidUpdateAsset(
        assets: releaseAssets,
        supportedAbis: supportedAbis,
      );
      final currentVersion = await currentInstalledVersion();
      final downloadUrl = selectedAsset?.downloadUrl ??
          data['html_url'] as String? ??
          '';
      if (selectedAsset != null) {
        debugPrint(
          '[UpdateChecker] Selected ${selectedAsset.name} for '
          '${supportedAbis.join(', ')}',
        );
      }

      final info = UpdateInfo(
        latestVersion: tagName,
        currentVersion: currentVersion,
        downloadUrl: downloadUrl,
        releaseNotes: body,
        isPreRelease: isPreRelease,
        isDirectApk: selectedAsset != null,
        packageLabel: selectedAsset == null
            ? null
            : androidUpdatePackageLabel(selectedAsset),
      );

      if (!info.hasUpdate) return null;

      // Check if user dismissed this version
      if (!force) {
        final dismissed = prefs.getString(_dismissedKey);
        if (dismissed == tagName) return null;
      }

      return info;
    } catch (e) {
      debugPrint('[UpdateChecker] Error: $e');
      return null;
    }
  }

  /// Dismiss the update prompt for a specific version.
  static Future<void> dismiss(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedKey, version);
  }
}

enum ApkInstallStatus {
  ok,
  downloadFailed,
  permissionDenied,
  launchFailed,
  cancelled,
}

class ApkInstallResult {
  final ApkInstallStatus status;
  final String? message;
  const ApkInstallResult(this.status, [this.message]);
}

/// Downloads the APK in-app and hands it to the system installer.
///
/// Why: launching the URL in a browser leaves Chrome holding the APK in its
/// SafeBrowsing "scanning" limbo - the download bar hits 100% and never
/// finalises. Pulling the bytes ourselves and opening the file with
/// open_filex bypasses the browser entirely.
class ApkUpdater {
  static http.Client? _activeClient;

  static Future<ApkInstallResult> downloadAndInstall(
    UpdateInfo info, {
    required void Function(int received, int total) onProgress,
  }) async {
    if (!Platform.isAndroid) {
      return const ApkInstallResult(ApkInstallStatus.launchFailed, 'Android only');
    }

    final perm = await Permission.requestInstallPackages.request();
    if (!perm.isGranted) {
      return const ApkInstallResult(ApkInstallStatus.permissionDenied);
    }

    final File file;
    try {
      file = await _download(info, onProgress);
    } on _CancelledException {
      return const ApkInstallResult(ApkInstallStatus.cancelled);
    } catch (e) {
      debugPrint('[ApkUpdater] Download failed: $e');
      return ApkInstallResult(ApkInstallStatus.downloadFailed, e.toString());
    }

    final result = await OpenFilex.open(file.path, type: 'application/vnd.android.package-archive');
    if (result.type != ResultType.done) {
      debugPrint('[ApkUpdater] OpenFilex failed: ${result.type} ${result.message}');
      return ApkInstallResult(ApkInstallStatus.launchFailed, result.message);
    }
    return const ApkInstallResult(ApkInstallStatus.ok);
  }

  /// Cancel an in-flight download started by [downloadAndInstall].
  static void cancel() {
    _activeClient?.close();
    _activeClient = null;
  }

  static Future<File> _download(
    UpdateInfo info,
    void Function(int, int) onProgress,
  ) async {
    final dir = await getTemporaryDirectory();
    final filename = Uri.parse(info.downloadUrl).pathSegments.last;
    final file = File('${dir.path}/$filename');
    if (await file.exists()) await file.delete();

    final client = http.Client();
    _activeClient = client;
    try {
      final request = http.Request('GET', Uri.parse(info.downloadUrl));
      final response = await client.send(request);
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final total = response.contentLength ?? 0;
      var received = 0;
      final sink = file.openWrite();
      try {
        await for (final chunk in response.stream) {
          if (_activeClient != client) {
            await sink.close();
            throw const _CancelledException();
          }
          sink.add(chunk);
          received += chunk.length;
          onProgress(received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      return file;
    } finally {
      if (_activeClient == client) _activeClient = null;
      client.close();
    }
  }
}

class _CancelledException implements Exception {
  const _CancelledException();
}
