import AbsorbPlayerCore
import AppIntents
import Flutter
import UIKit
import AVFoundation
import MediaPlayer
import just_audio

let flutterEngine = FlutterEngine(name: "SharedEngine", project: nil, allowHeadlessExecution: true)

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var widgetChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Start the shared Flutter engine (used by both phone scene and CarPlay scene)
    flutterEngine.run()
    GeneratedPluginRegistrant.register(with: flutterEngine)

    // Register for remote control events so lock screen / Control Center
    // media controls appear. The audio_service plugin activates
    // MPRemoteCommandCenter but doesn't call this, which can prevent
    // Now Playing from appearing on scene-based lifecycle apps.
    application.beginReceivingRemoteControlEvents()

    // Pre-configure audio session for playback so iOS knows this app
    // plays audio before the Flutter engine finishes initializing.
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .spokenAudio)
      try session.setActive(true)
    } catch {
      print("[AppDelegate] Audio session setup failed: \(error)")
    }

    // Listen for Darwin notifications from the widget extension so controls
    // work without opening the app.
    registerWidgetNotifications()

    // Register platform channels on the shared engine. Must come before the
    // logSink wiring below so widgetChannel exists when we hand it off.
    registerPlatformChannels()

    // Route native player core log output into the Flutter widget channel's
    // "log" method, which surfaces lines as `[WidgetDebug] [NativeCore] ...`
    // in absorb's in-app log viewer. No Mac/Xcode needed to verify behavior.
    AbsorbPlayerCore.logSink = { [weak self] line in
      DispatchQueue.main.async {
        self?.widgetChannel?.invokeMethod("log", arguments: ["msg": line])
      }
    }

    // Same routing for the EQ tap's format diagnostics, so when a user
    // reports "EQ on, this book has no sound" we can see the post-decode
    // PCM format the tap actually received (low-bitrate AAC m4b often
    // shows up here as mono / unusual sample rate).
    AudioEQProcessor.setFormatLogger { [weak self] line in
      DispatchQueue.main.async {
        self?.widgetChannel?.invokeMethod("log", arguments: ["msg": line])
      }
    }
    AbsorbAudioEQProcessor.setFormatLogger { [weak self] line in
      DispatchQueue.main.async {
        self?.widgetChannel?.invokeMethod("log", arguments: ["msg": line])
      }
    }

    IOSQueueAdvancer.logSink = { [weak self] line in
      DispatchQueue.main.async {
        self?.widgetChannel?.invokeMethod("log", arguments: ["msg": line])
      }
    }

    AbsorbAudioEngine.logSink = { [weak self] line in
      DispatchQueue.main.async {
        self?.widgetChannel?.invokeMethod("log", arguments: ["msg": line])
      }
    }
    AbsorbAudioBridge.logSink = { [weak self] line in
      DispatchQueue.main.async {
        self?.widgetChannel?.invokeMethod("log", arguments: ["msg": line])
      }
    }

    // Register the native player core as an AppIntent dependency. The widget
    // intent declares `@Dependency var core: AbsorbPlayerCoreProtocol` - that
    // signals to iOS to launch this host app process to run the intent's
    // perform(), and the dependency manager hands back this concrete instance
    // so the intent can drive audio in-process. Without this, the widget
    // intent runs in the widget extension's sandbox and can't reach our audio
    // engine.
    //
    // AppIntents (and AppDependencyManager) are iOS 16+. Runner ships back
    // to iOS 15 so we have to guard the call. iOS 15 users won't have the
    // widget anyway (widget extension's deployment target is iOS 17).
    if #available(iOS 16.0, *) {
      let core: AbsorbPlayerCoreProtocol = AbsorbPlayerCore.shared
      AppDependencyManager.shared.add(dependency: core)
      AbsorbPlayerCore.logSink?("[NativeCore] Registered as AppIntent dependency")
    }

    registerAudioSessionObservers()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerAudioSessionObservers() {
    let nc = NotificationCenter.default
    nc.addObserver(
      forName: AVAudioSession.routeChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] note in
      let reasonRaw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt ?? 0
      let reason = AVAudioSession.RouteChangeReason(rawValue: reasonRaw)
      let reasonName: String
      switch reason {
      case .unknown: reasonName = "unknown"
      case .newDeviceAvailable: reasonName = "newDeviceAvailable"
      case .oldDeviceUnavailable: reasonName = "oldDeviceUnavailable"
      case .categoryChange: reasonName = "categoryChange"
      case .override: reasonName = "override"
      case .wakeFromSleep: reasonName = "wakeFromSleep"
      case .noSuitableRouteForCategory: reasonName = "noSuitableRouteForCategory"
      case .routeConfigurationChange: reasonName = "routeConfigurationChange"
      default: reasonName = "raw=\(reasonRaw)"
      }
      let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        .map { "\($0.portType.rawValue):\($0.portName)" }
        .joined(separator: ",")
      self?.logToFlutter("[AudioSession] routeChange reason=\(reasonName) outputs=[\(outputs)]")
    }

    nc.addObserver(
      forName: AVAudioSession.interruptionNotification,
      object: nil,
      queue: .main
    ) { [weak self] note in
      let typeRaw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt ?? 99
      let type = AVAudioSession.InterruptionType(rawValue: typeRaw)
      let typeName: String
      switch type {
      case .began: typeName = "began"
      case .ended: typeName = "ended"
      default: typeName = "raw=\(typeRaw)"
      }
      var details: [String] = ["type=\(typeName)"]
      if let optionsRaw = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt {
        let opts = AVAudioSession.InterruptionOptions(rawValue: optionsRaw)
        details.append("shouldResume=\(opts.contains(.shouldResume))")
      }
      if #available(iOS 14.5, *) {
        if let reasonRaw = note.userInfo?[AVAudioSessionInterruptionReasonKey] as? UInt {
          details.append("reasonRaw=\(reasonRaw)")
        }
      }
      self?.logToFlutter("[AudioSession] interruption \(details.joined(separator: " "))")
    }

    nc.addObserver(
      forName: AVAudioSession.mediaServicesWereResetNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.logToFlutter("[AudioSession] mediaServicesWereReset")
    }

    nc.addObserver(
      forName: AVAudioSession.silenceSecondaryAudioHintNotification,
      object: nil,
      queue: .main
    ) { [weak self] note in
      let typeRaw = note.userInfo?[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt ?? 99
      self?.logToFlutter("[AudioSession] silenceSecondaryAudioHint type=\(typeRaw)")
    }

    // The patched just_audio fork posts JustAudioDiag notifications with
    // AVPlayer state snapshots (timeControlStatus, rate, reasonForWaitingToPlay,
    // error) right after each play() call. Forward them to the in-app log.
    nc.addObserver(
      forName: Notification.Name("JustAudioDiag"),
      object: nil,
      queue: .main
    ) { [weak self] note in
      if let msg = note.userInfo?["message"] as? String {
        self?.logToFlutter(msg)
      }
    }
  }

  /// Forwards a log line to the Dart LogService via the widget channel so it
  /// appears in the in-app log viewer (NSLog alone only shows in Xcode /
  /// Console.app on a Mac).
  private func logToFlutter(_ message: String) {
    NSLog("[WidgetDebug] %@", message)
    DispatchQueue.main.async { [weak self] in
      self?.widgetChannel?.invokeMethod("log", arguments: ["msg": message])
    }
  }

  private func registerWidgetNotifications() {
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    let observer = Unmanaged.passUnretained(self).toOpaque()

    let names = [
      "com.barnabas.absorb.widget.playPause",
      "com.barnabas.absorb.widget.skipBack",
      "com.barnabas.absorb.widget.skipForward",
    ]
    for name in names {
      CFNotificationCenterAddObserver(
        center, observer,
        { (_, observer, name, _, _) in
          guard let observer = observer,
                let rawName = name?.rawValue as String? else { return }
          NSLog("[WidgetDebug] AppDelegate received Darwin notification: %@", rawName)
          let appDelegate = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
          let action: String
          switch rawName {
          case "com.barnabas.absorb.widget.playPause":   action = "playPause"
          case "com.barnabas.absorb.widget.skipBack":    action = "skipBack"
          case "com.barnabas.absorb.widget.skipForward": action = "skipForward"
          default: return
          }
          // Re-activate the audio session as soon as the host app process
          // sees the notification, before the async hop to Flutter. The
          // widget extension already activates it in perform(), but doing it
          // again here from the host app's process is the belt-and-suspenders
          // guarantee that AVAudioSession is hot when player.play() runs.
          do {
            try AVAudioSession.sharedInstance().setActive(true)
          } catch {
            NSLog("[WidgetDebug] AppDelegate setActive failed: %@", error.localizedDescription)
          }
          DispatchQueue.main.async {
            NSLog("[WidgetDebug] AppDelegate dispatching widget action to Flutter: %@", action)
            appDelegate.widgetChannel?.invokeMethod("widgetAction", arguments: ["action": action])
          }
        },
        name as CFString,
        nil,
        .deliverImmediately
      )
    }
    NSLog("[WidgetDebug] AppDelegate registered %d Darwin notification observers", names.count)
  }

  private func registerPlatformChannels() {
    let messenger = flutterEngine.binaryMessenger

    IOSQueueAdvancer.shared.register(with: messenger)
    AbsorbAudioBridge.shared.register(with: messenger)

    // iOS audio output device switching is not implemented yet — iOS routes
    // through the system's MPVolumeView/AVRoutePicker rather than letting apps
    // pick output devices directly. Stub these so the channel responds.
    let channel = FlutterMethodChannel(name: "com.absorb.audio_output",
                                       binaryMessenger: messenger)
    channel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "getAudioOutputDevices":
        result([])
      case "setAudioOutputDevice", "resetAudioOutput":
        result(false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let storageChannel = FlutterMethodChannel(name: "com.absorb.storage",
                                              binaryMessenger: messenger)
    storageChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "getDeviceStorage":
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let total = (attrs[.systemSize] as? NSNumber)?.int64Value,
           let free = (attrs[.systemFreeSize] as? NSNumber)?.int64Value {
          result(["totalBytes": total, "availableBytes": free])
        } else {
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let widgetChannel = FlutterMethodChannel(name: "com.absorb.widget",
                                               binaryMessenger: messenger)
    self.widgetChannel = widgetChannel
    widgetChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "getGroupContainerPath":
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.barnabas.absorb") {
          NSLog("[WidgetDebug] getGroupContainerPath resolved: %@", url.path)
          result(url.path)
        } else {
          NSLog("[WidgetDebug] getGroupContainerPath: containerURL returned nil - app group entitlement missing or misconfigured")
          result(nil)
        }
      case "excludeFromBackup":
        // Stops iCloud from backing up downloaded audio files. Audiobooks
        // are large and re-downloadable, no point eating user's iCloud
        // quota. Called by DownloadService for each file post-download or
        // post-migration.
        let args = call.arguments as? [String: Any]
        guard let path = args?["path"] as? String else { result(false); return }
        var url = URL(fileURLWithPath: path)
        do {
          var values = URLResourceValues()
          values.isExcludedFromBackup = true
          try url.setResourceValues(values)
          result(true)
        } catch {
          NSLog("[WidgetDebug] excludeFromBackup failed for %@: %@", path, error.localizedDescription)
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let eqChannel = FlutterMethodChannel(name: "com.absorb.equalizer",
                                          binaryMessenger: messenger)
    eqChannel.setMethodCallHandler { [weak self] (call, result) in
      let args = call.arguments as? [String: Any]
      switch call.method {
      case "isBluetoothAudioConnected":
        result(self?.isBluetoothAudioConnected() ?? false)

      case "getAudioDiagnostics":
        // Snapshot of AVAudioSession state for the "tap play, no sound"
        // diagnosis. Returns category, mode, options, output volume,
        // current route ports, and the session-active hint that iOS
        // exposes. Dart side logs all of it via [AudioDiag] markers.
        let session = AVAudioSession.sharedInstance()
        let route = session.currentRoute
        let outputs = route.outputs.map { port -> [String: String] in
          [
            "name": port.portName,
            "type": port.portType.rawValue,
            "uid": port.uid,
          ]
        }
        let inputs = route.inputs.map { port -> [String: String] in
          [
            "name": port.portName,
            "type": port.portType.rawValue,
          ]
        }
        let npInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo
        let npTitle = npInfo?[MPMediaItemPropertyTitle] as? String
        let npRate = npInfo?[MPNowPlayingInfoPropertyPlaybackRate] as? Double
        let npElapsed = npInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? Double
        let info: [String: Any] = [
          "category": session.category.rawValue,
          "mode": session.mode.rawValue,
          "categoryOptions": session.categoryOptions.rawValue,
          "routeSharingPolicy": session.routeSharingPolicy.rawValue,
          "outputVolume": session.outputVolume,
          "isOtherAudioPlaying": session.isOtherAudioPlaying,
          "secondaryAudioShouldBeSilencedHint": session.secondaryAudioShouldBeSilencedHint,
          "outputs": outputs,
          "inputs": inputs,
          "sampleRate": session.sampleRate,
          "ioBufferDuration": session.ioBufferDuration,
          "nowPlayingHasInfo": npInfo != nil,
          "nowPlayingTitle": npTitle ?? "",
          "nowPlayingRate": npRate ?? -1,
          "nowPlayingElapsed": npElapsed ?? -1,
        ]
        result(info)

      case "primeNowPlaying":
        let title = args?["title"] as? String ?? ""
        let artist = args?["artist"] as? String ?? ""
        let duration = args?["duration"] as? Double ?? 0
        let elapsed = args?["elapsed"] as? Double ?? 0
        var info: [String: Any] = [
          MPMediaItemPropertyTitle: title,
          MPMediaItemPropertyArtist: artist,
          MPNowPlayingInfoPropertyPlaybackRate: 1.0,
          MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
        ]
        if duration > 0 {
          info[MPMediaItemPropertyPlaybackDuration] = duration
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        result(true)

      case "init":
        result([
          "bands": 5,
          "frequencies": [60, 230, 910, 3600, 14000],
          "minLevel": -15.0,
          "maxLevel": 15.0,
        ] as [String: Any])

      case "attachSession":
        // No-op on iOS - the processing tap is attached per player item in
        // UriAudioSource.m, not via a session ID like Android's EQ APIs.
        result(true)

      case "setEnabled":
        let enabled = args?["enabled"] as? Bool ?? false
        AudioEQProcessor.shared.setEnabled(enabled)
        AbsorbAudioEQProcessor.shared.setEnabled(enabled)
        result(true)

      case "setBand":
        let band = args?["band"] as? Int ?? 0
        let level = args?["level"] as? Int ?? 0
        AudioEQProcessor.shared.setBandLevel(Int32(level), forBand: Int32(band))
        AbsorbAudioEQProcessor.shared.setBandLevel(Int32(level), forBand: Int32(band))
        result(true)

      case "setBassBoost":
        let strength = args?["strength"] as? Int ?? 0
        AudioEQProcessor.shared.setBassBoostStrength(Int32(strength))
        AbsorbAudioEQProcessor.shared.setBassBoostStrength(Int32(strength))
        result(true)

      case "setVirtualizer":
        // No iOS equivalent of Android's Virtualizer effect.
        result(true)

      case "setLoudness":
        let gain = args?["gain"] as? Int ?? 0
        AudioEQProcessor.shared.setLoudnessGain(Int32(gain))
        AbsorbAudioEQProcessor.shared.setLoudnessGain(Int32(gain))
        result(true)

      case "setMono":
        let enabled = args?["enabled"] as? Bool ?? false
        AudioEQProcessor.shared.setMonoEnabled(enabled)
        AbsorbAudioEQProcessor.shared.setMonoEnabled(enabled)
        result(true)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func isBluetoothAudioConnected() -> Bool {
    let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
    return outputs.contains { port in
      port.portType == .bluetoothA2DP ||
      port.portType == .bluetoothHFP ||
      port.portType == .bluetoothLE
    }
  }

}
