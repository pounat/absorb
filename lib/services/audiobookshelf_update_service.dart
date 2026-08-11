import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AudiobookshelfServerUpdate {
  final String currentVersion;
  final String latestVersion;
  final String releaseUrl;

  const AudiobookshelfServerUpdate({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseUrl,
  });
}

class AudiobookshelfUpdateService {
  static final Uri _releasesUri = Uri.parse(
    'https://api.github.com/repos/advplyr/audiobookshelf/releases?per_page=30',
  );

  static Future<AudiobookshelfServerUpdate?> check({
    required String currentVersion,
    http.Client? httpClient,
  }) async {
    final current = _ServerVersion.tryParse(currentVersion);
    if (current == null) return null;

    final client = httpClient ?? http.Client();
    try {
      final response = await client
          .get(
            _releasesUri,
            headers: const {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return null;

      _ReleaseVersion? latest;
      for (final value in decoded) {
        if (value is! Map) continue;
        final tagName = value['tag_name']?.toString() ?? '';
        final version = _ServerVersion.tryParse(tagName);
        if (version == null) continue;
        if (latest == null || version.compareTo(latest.version) > 0) {
          latest = _ReleaseVersion(
            version: version,
            releaseUrl:
                value['html_url']?.toString() ??
                'https://github.com/advplyr/audiobookshelf/releases/tag/v${version.value}',
          );
        }
      }

      if (latest == null || latest.version.compareTo(current) <= 0) {
        return null;
      }
      return AudiobookshelfServerUpdate(
        currentVersion: current.value,
        latestVersion: latest.version.value,
        releaseUrl: latest.releaseUrl,
      );
    } catch (error) {
      debugPrint('[AudiobookshelfUpdate] Check failed: $error');
      return null;
    } finally {
      if (httpClient == null) client.close();
    }
  }
}

class AudiobookshelfUpdateController extends ChangeNotifier {
  AudiobookshelfUpdateController._();

  static final AudiobookshelfUpdateController instance =
      AudiobookshelfUpdateController._();

  AudiobookshelfServerUpdate? _update;
  String? _checkedFor;
  bool _isChecking = false;

  AudiobookshelfServerUpdate? get update => _update;
  String? get checkedFor => _checkedFor;
  bool get isChecking => _isChecking;

  bool shouldCheck(String currentVersion) {
    final version = currentVersion.trim();
    return version.isNotEmpty && _checkedFor != version;
  }

  Future<void> check({required String currentVersion}) async {
    final version = currentVersion.trim();
    if (version.isEmpty || !shouldCheck(version)) return;

    _checkedFor = version;
    _isChecking = true;
    _update = null;
    notifyListeners();

    final update = await AudiobookshelfUpdateService.check(
      currentVersion: version,
    );
    if (_checkedFor != version) return;

    _update = update;
    _isChecking = false;
    notifyListeners();
  }
}

class _ReleaseVersion {
  final _ServerVersion version;
  final String releaseUrl;

  const _ReleaseVersion({required this.version, required this.releaseUrl});
}

class _ServerVersion {
  final int major;
  final int minor;
  final int patch;
  final String value;

  const _ServerVersion({
    required this.major,
    required this.minor,
    required this.patch,
    required this.value,
  });

  static _ServerVersion? tryParse(String value) {
    final match = RegExp(
      r'^v?(\d+)\.(\d+)\.(\d+)(?:[-+][0-9A-Za-z.-]+)?$',
    ).firstMatch(value.trim());
    if (match == null) return null;
    final major = int.tryParse(match.group(1)!);
    final minor = int.tryParse(match.group(2)!);
    final patch = int.tryParse(match.group(3)!);
    if (major == null || minor == null || patch == null) return null;
    return _ServerVersion(
      major: major,
      minor: minor,
      patch: patch,
      value: '$major.$minor.$patch',
    );
  }

  int compareTo(_ServerVersion other) {
    final majorResult = major.compareTo(other.major);
    if (majorResult != 0) return majorResult;
    final minorResult = minor.compareTo(other.minor);
    if (minorResult != 0) return minorResult;
    return patch.compareTo(other.patch);
  }
}
