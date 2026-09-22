/// Configuration options for Google Cast functionality.
class GoogleCastOptions {
  /// Whether physical volume buttons will control device volume.
  final bool physicalVolumeButtonsWillControlDeviceVolume;

  /// Whether to disable discovery autostart.
  final bool disableDiscoveryAutostart;

  /// Whether to disable analytics logging.
  final bool disableAnalyticsLogging;

  /// Whether to suspend sessions when backgrounded.
  final bool suspendSessionsWhenBackgrounded;

  /// Whether to stop receiver application when ending session.
  final bool stopReceiverApplicationWhenEndingSession;

  /// Whether to start discovery after first tap on cast button.
  final bool startDiscoveryAfterFirstTapOnCastButton;

  /// Whether to automatically stop casting and end the session when the app is killed/terminated.
  ///
  /// When set to `true`, the plugin will automatically call `endSessionAndStopCasting()`
  /// when the app is terminated (killed by user or system). This ensures the Chromecast
  /// device stops playing when the app is closed.
  ///
  /// When set to `false` (default), casting will continue on the receiver device even
  /// after the app is killed, allowing the user to resume control later.
  ///
  /// Note: This works for normal app closure and most system-initiated kills.
  /// Force-kills (swipe away from recent apps) may not always trigger this behavior
  /// depending on the platform and circumstances.
  final bool stopCastingOnAppTerminated;

  /// Creates a new [GoogleCastOptions] instance.
  GoogleCastOptions({
    this.physicalVolumeButtonsWillControlDeviceVolume = true,
    this.disableDiscoveryAutostart = false,
    this.disableAnalyticsLogging = false,
    this.suspendSessionsWhenBackgrounded = true,
    this.stopReceiverApplicationWhenEndingSession = false,
    this.startDiscoveryAfterFirstTapOnCastButton = true,
    this.stopCastingOnAppTerminated = false,
  });

  /// Converts this options object to a map representation.
  Map<String, dynamic> toMap() {
    return {
      'physicalVolumeButtonsWillControlDeviceVolume':
          physicalVolumeButtonsWillControlDeviceVolume,
      'disableDiscoveryAutostart': disableDiscoveryAutostart,
      'disableAnalyticsLogging': disableAnalyticsLogging,
      'suspendSessionsWhenBackgrounded': suspendSessionsWhenBackgrounded,
      'stopReceiverApplicationWhenEndingSession':
          stopReceiverApplicationWhenEndingSession,
      'startDiscoveryAfterFirstTapOnCastButton':
          startDiscoveryAfterFirstTapOnCastButton,
      'stopCastingOnAppTerminated': stopCastingOnAppTerminated,
    };
  }
}
