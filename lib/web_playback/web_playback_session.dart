import 'dart:async';

/// Browser-only listening state; the native durable queues are not used.
class WebPlaybackSession {
  static double resumePosition(
    double sessionPosition,
    Map<String, dynamic>? progress,
  ) {
    if (progress == null) return 0; // Strict reader confirmed no server row.
    final server = (progress['currentTime'] as num?)?.toDouble();
    if (progress['isFinished'] == true ||
        server == null ||
        !server.isFinite ||
        server < 0)
      return sessionPosition;
    return server;
  }

  WebPlaybackSession({
    required this.clock,
    required this.send,
    this.readProgress,
    this.nativeSessionSync = false,
    this.syncTimeout = const Duration(seconds: 9),
    this.onWarning,
    double serverPosition = 0,
  }) : _serverPosition = serverPosition;
  /// Production browser callers must supply ApiService.getWebItemProgress:
  /// null means confirmed 404, while unavailable/invalid reads must throw.
  final Future<Map<String, dynamic>?> Function()? readProgress;
  /// ABS follows native session cadence; BookOrbit retains its qualified policy.
  final bool nativeSessionSync;
  final Duration syncTimeout;
  final void Function()? onWarning;
  int consecutiveFailures = 0;
  int warningSerial = 0;
  bool _attempted = false;
  double _serverPosition;
  final Duration Function() clock;
  final Future<int?> Function(double position, int listened) send;
  Duration? _sampleAt;
  Duration? _sentAt;
  double _position = 0;
  double _pending = 0;
  bool _audible = false;
  double _rate = 1;

  void sample(double position, {required bool audible, double rate = 1}) {
    final now = clock();
    _sentAt ??= now;
    final seconds = _sampleAt == null
        ? 0.0
        : (now - _sampleAt!).inMicroseconds / 1e6;
    final distance = position - _position;
    if (_audible &&
        seconds > 0 &&
        distance > 0 &&
        _rate > 0 &&
        distance <= seconds * _rate + 0.5) {
      _pending += (distance / _rate).clamp(0.0, seconds);
      if (nativeSessionSync) _pending = _pending.clamp(0.0, 60.0);
    }
    _sampleAt = now;
    _position = position;
    _audible = audible;
    _rate = rate;
  }

  Future<void>? _flight;
  bool _queued = false;

  Future<void> checkpoint({bool force = false}) {
    if (recoveryRequired || _retired || _closing) return Future.value();
    if (nativeSessionSync && !_attempted && _pending < 1) return Future.value();
    final now = clock();
    if (!force &&
        (_sentAt == null || now - _sentAt! < Duration(seconds: nativeSessionSync && !_attempted ? 20 : 10)))
      return Future.value();
    if (_flight != null) {
      _queued = _queued || !nativeSessionSync || force;
      // Keep one waiter, not an offline queue of timer callbacks.
      return nativeSessionSync ? Future.value() : _flight!;
    }
    final done = Completer<void>();
    _flight = done.future;
    () async {
      do {
        _queued = false;
        await _write();
      } while (_queued && !recoveryRequired && !_retired && !_closing);
      _flight = null;
      done.complete();
    }();
    return done.future;
  }

  Future<void> _write() async {
    _sentAt = clock();
    if (nativeSessionSync) {
      _attempted = true;
    } else if (readProgress != null) {
      try {
        final progress = await readProgress!();
        final server = (progress?['currentTime'] as num?)?.toDouble();
        // ABS has no CAS: compare with our last confirmed write, not the
        // furthest position. A rewind on another device is still newer truth.
        if ((server == null && _serverPosition != 0) ||
            (server != null &&
                (!server.isFinite || (server - _serverPosition).abs() > 1))) {
          recoveryRequired = true;
          failureStatus = 409;
          _pending = 0;
          return;
        }
      } catch (_) {
        recoveryRequired = true;
        _pending = 0;
        return;
      }
    }
    if (_retired) return;
    final sentPosition = _position;
    final listened = _pending.floor();
    _pending -= listened;
    if (nativeSessionSync) {
      await _writeNative(sentPosition, listened);
      return;
    }
    try {
      failureStatus = await send(sentPosition, listened);
    } catch (_) {
      failureStatus = null;
    }
    recoveryRequired = failureStatus != 200;
    if (!recoveryRequired) _serverPosition = sentPosition;
    if (recoveryRequired) _pending = 0;
  }

  void _nativeFailure(int? status) {
    failureStatus = status;
    failureReason = status == null ? 'write-unconfirmed' : 'write-http';
    // Invalid authority cannot be retried. This is a write quarantine, not a
    // media pause. 409 includes the unchanged BFF's uncertain/stale owner fence.
    recoveryRequired = const [401, 403, 404, 409].contains(status);
    _queued = false;
    _pending = 0;
    consecutiveFailures++;
    if (recoveryRequired || consecutiveFailures >= 4) {
      warningSerial++;
      consecutiveFailures = 0;
      onWarning?.call();
    }
  }

  Future<void> _writeNative(double position, int listened) async {
    var timedOut = false;
    // A Future.timeout does not cancel HTTP. Hold the flight until the actual
    // transport settles; never overlap or apply a late acknowledgment as saved.
    final deadline = Timer(syncTimeout, () {
      if (_retired) return;
      timedOut = true;
      _nativeFailure(null);
    });
    int? status;
    try { status = await send(position, listened); } catch (_) { status = null; }
    deadline.cancel();
    if (_retired) return;
    if (timedOut) {
      _queued = false;
      // A late denial can still revoke write authority, never restore it.
      if (const [401, 403, 404, 409].contains(status)) {
        recoveryRequired = true;
        failureStatus = status;
        failureReason = 'write-http';
        onWarning?.call();
      }
      return;
    }
    if (status != 200) { _nativeFailure(status); return; }
    failureStatus = 200;
    failureReason = null;
    consecutiveFailures = 0;
    _serverPosition = position;
  }

  bool _retired = false;
  bool _closing = false;
  void retire() {
    _retired = true;
    _queued = false;
    _pending = 0;
  }

  Future<void> close(Future<void> Function() sendClose) async {
    if (_closing || _retired) return;
    _closing = true;
    await _flight;
    if (!_retired && !(nativeSessionSync && recoveryRequired)) {
      await sendClose(); // Empty close only: never resend a delta.
    }
    retire();
  }

  Future<double?> recoveryPosition({
    required Future<Map<String, dynamic>?> Function() readProgress,
    required Future<Map<String, dynamic>?> Function() readSession,
    bool useLocalCheckpoint = false,
  }) async {
    // Reads are evidence only. An uncertain increment is deliberately discarded,
    // never inferred from timeListening or replayed into the replacement.
    await _flight;
    final progress = await readProgress();
    await readSession();
    // The browser reader returns null ONLY for confirmed absence. Explicit
    // server-first recovery may therefore reset a deleted/unstarted row to zero.
    final server = progress == null
        ? 0.0 : (progress['currentTime'] as num?)?.toDouble();
    if (_retired || server == null || !server.isFinite || server < 0)
      return null;
    return useLocalCheckpoint ? _position : server;
  }

  bool recoveryRequired = false;
  int? failureStatus;
  String? failureReason;
}
