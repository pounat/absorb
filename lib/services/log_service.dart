import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/text_file_download.dart';
import 'api_service.dart';

class LogService {
  static final LogService _instance = LogService._();
  factory LogService() => _instance;
  LogService._();

  static const supportEmail = 'absorb@barnabashq.com';

  // Keep 1MB max, trim to 512KB.
  static const _maxSize = 1 * 1024 * 1024; // 1 MB
  static const _keepSize = 512 * 1024; // 512 KB
  static const _rotateCheckInterval = 500; // check every N writes
  static const _createdAtKey = 'log_created_at';

  File? _logFile;
  final List<String> _webLogEntries = [];
  int _webLogSizeBytes = 0;
  bool _enabled = false;
  DebugPrintCallback? _originalDebugPrint;
  int _writeCount = 0;

  bool get enabled => _enabled;

  /// Call once at startup. If [loggingEnabled] is true, sets up the log file
  /// and overrides [debugPrint] to capture all output.
  Future<void> init(bool loggingEnabled) async {
    _enabled = loggingEnabled;
    if (!_enabled) return;

    if (kIsWeb) {
      _resetWebLogs();
      final now = DateTime.now().toIso8601String();
      _appendWebLog(
        '\n=== Session started $now (App Version: ${ApiService.appVersionFull}) ===\n',
      );
      _originalDebugPrint = debugPrint;
      debugPrint = _interceptedDebugPrint;
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/absorb_logs.txt');

    // Auto-clear if log is older than 24 hours.
    // Track creation time via a sidecar file since lastModified updates
    // on every write and can't be used for age checks.
    final createdAtFile = File('${dir.path}/$_createdAtKey');
    bool shouldClear = false;
    if (_logFile!.existsSync() && createdAtFile.existsSync()) {
      try {
        final createdMs = int.tryParse(createdAtFile.readAsStringSync().trim());
        if (createdMs != null) {
          final age = DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(createdMs),
          );
          if (age.inHours >= 24) shouldClear = true;
        }
      } catch (_) {
        shouldClear = true;
      }
    }

    if (shouldClear || !_logFile!.existsSync() || !createdAtFile.existsSync()) {
      // Start fresh - write device/server info header
      final header = StringBuffer()
        ..writeln('=== Absorb Log ===')
        ..writeln('App Version: ${ApiService.appVersionFull}')
        ..writeln(
          'Device: ${ApiService.deviceManufacturer} ${ApiService.deviceModel}',
        )
        ..writeln(
          'OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        )
        ..writeln('Created: ${DateTime.now().toIso8601String()}')
        ..writeln('==================')
        ..writeln();
      await _logFile!.writeAsString(header.toString());
      createdAtFile.writeAsStringSync(
        DateTime.now().millisecondsSinceEpoch.toString(),
      );
    }

    // Rotate on startup if needed
    await _rotateIfNeeded();

    // Session header - stamps the app version here too, since the file
    // header above only gets rewritten on clear/24h rollover and can go
    // stale across an app update in between.
    final now = DateTime.now().toIso8601String();
    await _logFile!.writeAsString(
      '\n=== Session started $now (App Version: ${ApiService.appVersionFull}) ===\n',
      mode: FileMode.append,
    );

    // Override debugPrint globally
    _originalDebugPrint = debugPrint;
    debugPrint = _interceptedDebugPrint;
  }

  void _interceptedDebugPrint(String? message, {int? wrapWidth}) {
    _originalDebugPrint?.call(message, wrapWidth: wrapWidth);
    if (message == null) return;
    final ts = DateTime.now().toIso8601String();
    final sanitized = _sanitize(message);
    final entry = '[$ts] $sanitized\n';
    if (kIsWeb) {
      _appendWebLog(entry);
    } else if (_logFile != null) {
      _logFile!.writeAsStringSync(entry, mode: FileMode.append);
      _maybeRotate();
    }
  }

  /// Write a log entry directly (for error handlers that bypass debugPrint).
  void log(String message) {
    final ts = DateTime.now().toIso8601String();
    final sanitized = _sanitize(message);
    final entry = '[$ts] $sanitized\n';
    if (kIsWeb) {
      if (_enabled) _appendWebLog(entry);
    } else if (_logFile != null) {
      _logFile!.writeAsStringSync(entry, mode: FileMode.append);
      _maybeRotate();
    }
  }

  void _appendWebLog(String entry) {
    var storedEntry = entry;
    var entryBytes = utf8.encode(storedEntry);
    if (entryBytes.length > _keepSize) {
      storedEntry = utf8.decode(
        entryBytes.sublist(entryBytes.length - _keepSize),
        allowMalformed: true,
      );
      entryBytes = utf8.encode(storedEntry);
    }

    _webLogEntries.add(storedEntry);
    _webLogSizeBytes += entryBytes.length;
    if (_webLogSizeBytes <= _maxSize) return;

    while (_webLogEntries.length > 1 && _webLogSizeBytes > _keepSize) {
      final removed = _webLogEntries.removeAt(0);
      _webLogSizeBytes -= utf8.encode(removed).length;
    }
  }

  String _logHeader() {
    final os = kIsWeb
        ? 'Web browser'
        : '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    return (StringBuffer()
          ..writeln('=== Absorb Log ===')
          ..writeln('App Version: ${ApiService.appVersionFull}')
          ..writeln(
            'Device: ${ApiService.deviceManufacturer} ${ApiService.deviceModel}',
          )
          ..writeln('OS: $os')
          ..writeln('Created: ${DateTime.now().toIso8601String()}')
          ..writeln('==================')
          ..writeln())
        .toString();
  }

  void _resetWebLogs() {
    _webLogEntries.clear();
    _webLogSizeBytes = 0;
    _appendWebLog(_logHeader());
  }

  /// Periodic runtime rotation - check file size every [_rotateCheckInterval]
  /// writes so the log never grows much past [_maxSize] even during long
  /// sessions. This keeps the most recent entries and trims the oldest.
  void _maybeRotate() {
    _writeCount++;
    if (_writeCount < _rotateCheckInterval) return;
    _writeCount = 0;
    // Run async rotation in the background - don't block the write path.
    // Writes between the check and the trim are fine; they just append
    // and the next rotation pass will catch them.
    _rotateIfNeeded();
  }

  /// If the log file exceeds [_maxSize], keep only the last [_keepSize] bytes.
  /// Trims at a newline boundary so partial lines aren't left at the top.
  Future<void> _rotateIfNeeded() async {
    try {
      if (_logFile == null || !await _logFile!.exists()) return;
      final size = await _logFile!.length();
      if (size <= _maxSize) return;

      final contents = await _logFile!.readAsString();
      final trimStart = contents.length - _keepSize;
      // Find the next newline after the trim point so we don't start
      // mid-line, which makes logs confusing to read.
      var cutAt = contents.indexOf('\n', trimStart);
      if (cutAt < 0) cutAt = trimStart;
      await _logFile!.writeAsString(contents.substring(cutAt + 1));
    } catch (_) {
      // Don't let rotation errors break logging
    }
  }

  Future<void> clearLogs() async {
    if (kIsWeb) {
      _resetWebLogs();
      return;
    }
    if (_logFile != null && await _logFile!.exists()) {
      // Write a fresh header immediately so logs shared in the same session
      // still have device info (don't wait for next init/restart).
      final header = StringBuffer()
        ..writeln('=== Absorb Log ===')
        ..writeln('App Version: ${ApiService.appVersionFull}')
        ..writeln(
          'Device: ${ApiService.deviceManufacturer} ${ApiService.deviceModel}',
        )
        ..writeln(
          'OS: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        )
        ..writeln('Created: ${DateTime.now().toIso8601String()}')
        ..writeln('==================')
        ..writeln();
      await _logFile!.writeAsString(header.toString());
      // Reset creation timestamp
      try {
        final dir = _logFile!.parent;
        final createdAtFile = File('${dir.path}/$_createdAtKey');
        createdAtFile.writeAsStringSync(
          DateTime.now().millisecondsSinceEpoch.toString(),
        );
      } catch (_) {}
    }
  }

  /// Build device info string used by both email methods.
  String _deviceInfo({String? serverVersion}) {
    final buf = StringBuffer()
      ..writeln('App Version: ${ApiService.appVersionFull}')
      ..writeln(
        'Device: ${ApiService.deviceManufacturer} ${ApiService.deviceModel}',
      )
      ..writeln('Device ID: ${ApiService.deviceId}');
    if (serverVersion != null) {
      buf.writeln('Server Version: $serverVersion');
    }
    buf.writeln('Timestamp: ${DateTime.now().toIso8601String()}');
    return buf.toString();
  }

  /// Params whose values should be masked in logged URLs.
  static final _sensitiveParamPattern = RegExp(
    r'token|code|secret|password|key|verifier|challenge|state|cookie|auth|bearer',
    caseSensitive: false,
  );

  /// Sanitize a single log message: mask URLs, sensitive query params, and
  /// bare key=value pairs that look like credentials.
  static String _sanitize(String message) {
    var result = _sanitizeUrls(message);
    // Mask standalone sensitive key=value pairs not inside URLs
    // (e.g. "token=abc123" in non-URL context)
    result = result.replaceAllMapped(
      RegExp(
        r'(token|secret|password|authorization|bearer|\w*key)\s*[=:]\s*(?!null\b|\*\*\*|true\b|false\b)\S+',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}=***',
    );
    return result;
  }

  /// Sanitize URLs in log content, replacing server hosts with a connection
  /// type label (e.g. [local-ip], [tailscale], [reverse-proxy]) while keeping
  /// API paths intact for debugging.
  static String _sanitizeUrls(String content) {
    // Collect unique hostnames found in URLs so we can scrub bare references too
    final foundHosts = <String>{};

    final urlPattern = RegExp(r'https?://[^\s\]"]+');
    var result = content.replaceAllMapped(urlPattern, (match) {
      final url = match.group(0)!;
      try {
        final uri = Uri.parse(url);
        final host = uri.host.toLowerCase();
        foundHosts.add(host);
        String label;
        if (host == 'localhost' || host == '127.0.0.1') {
          label = '[localhost]';
        } else if (host.endsWith('.ts.net')) {
          label = '[tailscale]';
        } else if (_isPrivateIp(host)) {
          label = '[local-ip]';
        } else if (uri.scheme == 'https') {
          label = '[reverse-proxy]';
        } else {
          label = '[remote-http]';
        }
        final path = uri.path.isNotEmpty ? uri.path : '';
        final query = _maskQuery(uri);
        return '$label$path$query';
      } catch (_) {
        return '[url-redacted]';
      }
    });

    // Scrub bare hostnames that leak in error messages (e.g. SocketException
    // includes "address = hostname.com, port = 1234")
    for (final host in foundHosts) {
      if (host == 'localhost' || host == '127.0.0.1') continue;
      result = result.replaceAll(host, '[host-redacted]');
    }
    return result;
  }

  /// Keep query param names but mask values of sensitive ones.
  static String _maskQuery(Uri uri) {
    if (uri.queryParameters.isEmpty) return '';
    final masked = uri.queryParameters.entries
        .map((e) {
          if (_sensitiveParamPattern.hasMatch(e.key)) {
            return '${e.key}=***';
          }
          return '${e.key}=${e.value}';
        })
        .join('&');
    return '?$masked';
  }

  static bool _isPrivateIp(String host) {
    final parts = host.split('.');
    if (parts.length != 4) return false;
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    if (a == null || b == null) return false;
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
  }

  /// Share log file as attachment via share sheet with device info.
  ///
  /// [sharePositionOrigin] is required on iPad for the share popover anchor.
  Future<void> shareLogs({
    String? serverVersion,
    Rect? sharePositionOrigin,
  }) async {
    final info = _deviceInfo(serverVersion: serverVersion);

    if (kIsWeb) {
      final logs = _webLogEntries.join();
      final content = logs.isNotEmpty
          ? '${_sanitizeUrls(logs)}\n=== Report Info ===\n$info'
          : '=== Absorb Log Report ===\n$info\n(No log data found — is logging enabled?)\n';
      await downloadTextFile(fileName: 'absorb_logs.txt', content: content);
      return;
    }

    final hasFile =
        _logFile != null &&
        await _logFile!.exists() &&
        await _logFile!.length() > 0;

    if (hasFile) {
      // Write sanitized copy to share instead of raw logs
      final raw = await _logFile!.readAsString();
      final sanitized = _sanitizeUrls(raw);
      final dir = _logFile!.parent;
      final sanitizedFile = File('${dir.path}/absorb_logs_share.txt');
      await sanitizedFile.writeAsString(sanitized);

      await Share.shareXFiles(
        [XFile(sanitizedFile.path)],
        subject: 'Absorb Log Report',
        text: 'Send to: $supportEmail\n\n$info',
        sharePositionOrigin: sharePositionOrigin,
      );
    } else {
      await Share.share(
        'Send to: $supportEmail\n\n$info\n(No log file found — is logging enabled?)',
        subject: 'Absorb Log Report',
        sharePositionOrigin: sharePositionOrigin,
      );
    }
  }

  /// Open a mailto: link with device info (no logs) for general contact.
  Future<void> contactEmail({String? serverVersion}) async {
    final info = _deviceInfo(serverVersion: serverVersion);
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: _encodeMailtoQuery({'subject': 'Absorb Feedback', 'body': info}),
    );
    await launchUrl(uri);
  }

  String _encodeMailtoQuery(Map<String, String> params) {
    return params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
