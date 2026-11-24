/// Why a cast session last ended, failed to start or was suspended, as
/// Android's Cast framework reported it. A code of 0 on an ended session
/// means it was ended on purpose (the app, the notification, or the system's
/// output picker), where a lost connection carries an error code.
class GoogleCastSessionEnd {
  /// ended, startFailed, resumeFailed or suspended.
  final String event;
  /// The Cast status code that came with it.
  final int code;
  /// When it was reported.
  final DateTime at;

  /// One report from the Cast framework.
  const GoogleCastSessionEnd(this.event, this.code, this.at);

  /// The most recent one, null until something has ended.
  static GoogleCastSessionEnd? last;
}
