import AbsorbPlayerCore
import AppIntents
import Flutter
import UIKit
import AVFoundation
import AVKit
import CoreMedia
import MediaPlayer
import just_audio

let flutterEngine = FlutterEngine(name: "SharedEngine", project: nil, allowHeadlessExecution: true)

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var widgetChannel: FlutterMethodChannel?
  private var volumeKeysChannel: FlutterMethodChannel?
  private let volumeKeyWatcher = VolumeKeyWatcher()

  // Native log lines emitted before Dart's channel handler registers, kept
  // with their uptime so the flush can stamp when they happened. Flutter
  // buffers only ONE pre-handler message per channel, so early lines
  // (notably [NowPlayingPrimer]) otherwise overwrite each other and never
  // reach the shared log.
  private var pendingNativeLogs: [(Double, String)] = []
  private var dartLogReady = false
  private let launchUptime = ProcessInfo.processInfo.systemUptime

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

    // Pre-configure the audio session category for playback so iOS knows this
    // app plays long-form audio (lock screen / Control Center controls) before
    // the Flutter engine finishes initializing. Activating the session is left
    // to [NowPlayingPrimer], which only does it when no other app is playing -
    // activating unconditionally here would interrupt Spotify the moment
    // Absorb opens. The playback paths (AbsorbAudioEngine / AbsorbPlayerCore /
    // IOSQueueAdvancer) activate it themselves when audio actually starts.
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .spokenAudio)
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
      self?.logToFlutter(line)
    }

    NowPlayingPrimer.logSink = { [weak self] line in
      self?.logToFlutter(line)
    }

    // Same routing for the EQ tap's format diagnostics, so when a user
    // reports "EQ on, this book has no sound" we can see the post-decode
    // PCM format the tap actually received (low-bitrate AAC m4b often
    // shows up here as mono / unusual sample rate).
    AudioEQProcessor.setFormatLogger { [weak self] line in
      self?.logToFlutter(line)
    }
    AbsorbAudioEQProcessor.setFormatLogger { [weak self] line in
      self?.logToFlutter(line)
    }

    IOSQueueAdvancer.logSink = { [weak self] line in
      self?.logToFlutter(line)
    }

    AbsorbAudioEngine.logSink = { [weak self] line in
      self?.logToFlutter(line)
    }
    AbsorbAudioBridge.logSink = { [weak self] line in
      self?.logToFlutter(line)
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

    // Wire the native core's lock-screen / headphone command handlers now,
    // at launch. They defer to Flutter while it's alive, but they must exist
    // before the first remote command lands: when a headset press makes iOS
    // cold-launch a killed Absorb into the background, didEnterBackground
    // never fires (the app was never foreground) and Flutter's own handlers
    // take about a second to register, so a play delivered in that window
    // would land on nothing. Armed natively, it plays from the app-group
    // stash and Flutter adopts the running engine when it finishes booting.
    AbsorbPlayerCore.shared.armRemoteCommands()

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
      var reasonRaw: UInt = 0
      if #available(iOS 14.5, *) {
        if let r = note.userInfo?[AVAudioSessionInterruptionReasonKey] as? UInt {
          reasonRaw = r
          details.append("reasonRaw=\(r)")
        }
      }
      self?.logToFlutter("[AudioSession] interruption \(details.joined(separator: " "))")
      // reason 4 = routeDisconnected: the headphones left, so iOS tore the
      // session down as an "interruption" that never gets an ended event -
      // waiting for one leaves the Now Playing claim dead and the next
      // headset press goes to Apple Music. There is no interrupter to yield
      // to here, so Dart takes the claim back right away.
      if typeName == "began", reasonRaw == 4 {
        self?.widgetChannel?.invokeMethod("reassertClaim", arguments: nil)
      }
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
  /// Console.app on a Mac). Lines emitted before Dart signals "logReady" are
  /// buffered and flushed then.
  private func logToFlutter(_ message: String) {
    NSLog("[WidgetDebug] %@", message)
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      if self.dartLogReady {
        self.widgetChannel?.invokeMethod("log", arguments: ["msg": message])
      } else {
        self.pendingNativeLogs.append((ProcessInfo.processInfo.systemUptime, message))
        if self.pendingNativeLogs.count > 400 {
          self.pendingNativeLogs.removeFirst(self.pendingNativeLogs.count - 400)
        }
      }
    }
  }

  private func registerWidgetNotifications() {
    let center = CFNotificationCenterGetDarwinNotifyCenter()
    let observer = Unmanaged.passUnretained(self).toOpaque()

    let names = [
      "com.barnabas.absorb.widget.playPause",
      "com.barnabas.absorb.widget.skipBack",
      "com.barnabas.absorb.widget.skipForward",
      "com.barnabas.absorb.host.takeover",
    ]
    for name in names {
      CFNotificationCenterAddObserver(
        center, observer,
        { (_, observer, name, _, _) in
          guard let observer = observer,
                let rawName = name?.rawValue as String? else { return }
          NSLog("[WidgetDebug] AppDelegate received Darwin notification: %@", rawName)
          let appDelegate = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()

          // A foreground process claimed audio ownership. If that's not us,
          // stop this process's engine so two streams can't overlap (#285).
          // Ownership is arbitrated by pid: the owner reads its own pid back
          // and ignores its own broadcast.
          if rawName == "com.barnabas.absorb.host.takeover" {
            DispatchQueue.main.async {
              if absorbAudioOwnerPid() == Int(getpid()) { return }
              if UIApplication.shared.applicationState == .active { return }
              NSLog("[WidgetDebug] takeover: another process claimed audio, stopping this process's engine")
              AbsorbPlayerCore.shared.yieldToForegroundOwner()
            }
            return
          }

          let action: String
          switch rawName {
          case "com.barnabas.absorb.widget.playPause":   action = "playPause"
          case "com.barnabas.absorb.widget.skipBack":    action = "skipBack"
          case "com.barnabas.absorb.widget.skipForward": action = "skipForward"
          default: return
          }
          // Every live process receives this broadcast, so exactly one may
          // act on it: the audio owner, and only via a Flutter that is
          // actually responsive. Anything else would actuate in parallel -
          // a stray background process's headless Flutter toggling next to
          // the foreground app is how one widget tap produced two streams
          // of the same book (#285), and a suspended-then-resumed Flutter
          // replaying the action after the native core already handled it
          // is how the play state got double-toggled.
          let myPid = Int(getpid())
          guard absorbAudioOwnerPid() == myPid, absorbFlutterAlive(pid: myPid) else {
            NSLog("[WidgetDebug] AppDelegate dropping widget action \(action) (owner=\(absorbAudioOwnerPid()) me=\(myPid)) - the acting process's native core covers it")
            return
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

  /// Mark this process as the foreground audio owner and tell any other process
  /// (e.g. one a widget play intent launched in the background) to stop its
  /// engine, so two streams can't overlap (#285). A no-op when this is the only
  /// process. Called from SceneDelegate.sceneDidBecomeActive.
  func claimAudioOwnershipAndNotifyOthers() {
    let defaults = UserDefaults(suiteName: absorbAppGroup)
    defaults?.set(Int(getpid()), forKey: "audio_owner_pid")
    // Sweep heartbeat keys left by long-dead processes - each app launch
    // writes its own pid-scoped key, so without this they pile up forever.
    if let dict = defaults?.dictionaryRepresentation() {
      let nowMs = Int(Date().timeIntervalSince1970 * 1000)
      let myKey = "flutter_alive_at_\(getpid())"
      for (key, value) in dict where key.hasPrefix("flutter_alive_at_") && key != myKey {
        if let ts = value as? Int, nowMs - ts > 3_600_000 {
          defaults?.removeObject(forKey: key)
        }
      }
    }
    postAbsorbDarwinNotification("com.barnabas.absorb.host.takeover")
  }

  private func registerPlatformChannels() {
    let messenger = flutterEngine.binaryMessenger

    IOSQueueAdvancer.shared.register(with: messenger)
    AbsorbAudioBridge.shared.register(with: messenger)

    // CarPlay Now Playing custom buttons (chapter nav, speed, bookmark). These
    // decorate CPNowPlayingTemplate only — the lock screen is untouched.
    CarPlayNowPlaying.shared.register(with: messenger)

    // iOS audio output device switching is not implemented yet — iOS routes
    // through the system's MPVolumeView/AVRoutePicker rather than letting apps
    // pick output devices directly. Stub those, but do expose the AirPlay
    // picker (the one piece the in-app button needs).
    let channel = FlutterMethodChannel(name: "com.absorb.audio_output",
                                       binaryMessenger: messenger)
    channel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "getAudioOutputDevices":
        result([])
      case "setAudioOutputDevice", "resetAudioOutput":
        result(false)
      case "showRoutePicker":
        // There is no public API to present the AirPlay picker directly, so
        // add a transient AVRoutePickerView to the key window and tap its
        // button. The view is removed again shortly after.
        DispatchQueue.main.async {
          let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
          let host = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
            ?? scenes.flatMap { $0.windows }.first
          guard let window = host else { result(false); return }
          let picker = AVRoutePickerView(frame: CGRect(x: -1000, y: -1000, width: 0, height: 0))
          picker.prioritizesVideoDevices = false
          window.addSubview(picker)
          func findButton(_ view: UIView) -> UIButton? {
            if let b = view as? UIButton { return b }
            for sub in view.subviews { if let b = findButton(sub) { return b } }
            return nil
          }
          var triggered = false
          if let button = findButton(picker) {
            button.sendActions(for: .touchUpInside)
            triggered = true
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            picker.removeFromSuperview()
          }
          result(triggered)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Ebook reader: volume keys turn pages. Watching intercepts presses via
    // an outputVolume observer and resets the level so volume never moves.
    let volKeys = FlutterMethodChannel(name: "com.absorb.volume_keys",
                                       binaryMessenger: messenger)
    volumeKeysChannel = volKeys
    volumeKeyWatcher.onPressed = { [weak self] direction in
      self?.volumeKeysChannel?.invokeMethod("volumePressed", arguments: direction)
    }
    volKeys.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "watch":
        self?.volumeKeyWatcher.start()
        result(true)
      case "clearWatch":
        self?.volumeKeyWatcher.stop()
        result(true)
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

    // Bookmark clip export: extract a time window of a book and write a .m4a.
    let clipChannel = FlutterMethodChannel(name: "com.absorb.clip",
                                           binaryMessenger: messenger)
    clipChannel.setMethodCallHandler { (call, result) in
      guard call.method == "exportClip" else { result(FlutterMethodNotImplemented); return }
      let args = call.arguments as? [String: Any]
      guard let source = args?["source"] as? String,
            let outPath = args?["outPath"] as? String else {
        result(FlutterError(code: "CLIP_ARGS", message: "Missing source or outPath", details: nil))
        return
      }
      let isLocal = args?["isLocal"] as? Bool ?? true
      let headers = args?["headers"] as? [String: String]
      let start = args?["startSeconds"] as? Double ?? 0
      let duration = args?["durationSeconds"] as? Double ?? 60
      AudioClipExporter.exportM4a(
        source: source, isLocal: isLocal, headers: headers,
        startSeconds: start, durationSeconds: duration, outPath: outPath
      ) { ok, errMessage in
        DispatchQueue.main.async {
          if ok {
            result(true)
          } else {
            result(FlutterError(code: "CLIP_FAILED", message: errMessage ?? "export failed", details: nil))
          }
        }
      }
    }

    // Lock screen skip amounts. iOS bakes these into the command center's
    // preferredIntervals rather than reading them per press, so Dart pushes the
    // effective amounts here whenever they change.
    let playerCoreChannel = FlutterMethodChannel(name: "com.absorb.player_core",
                                                 binaryMessenger: messenger)
    playerCoreChannel.setMethodCallHandler { (call, result) in
      guard call.method == "setSkipIntervals" else { result(FlutterMethodNotImplemented); return }
      let args = call.arguments as? [String: Any]
      guard let forward = args?["forward"] as? Int,
            let backward = args?["backward"] as? Int else {
        result(FlutterError(code: "SKIP_ARGS", message: "Missing forward or backward", details: nil))
        return
      }
      AbsorbPlayerCore.shared.setSkipIntervals(forward: forward, backward: backward)
      result(true)
    }

    // On-device bookmark transcription: decode a window of a downloaded audio
    // file into 16kHz mono WAV for Whisper. AVAssetReader does the resample +
    // downmix for us; no ffmpeg ships in the app.
    let transcriptionChannel = FlutterMethodChannel(name: "com.barnabas.absorb/transcription",
                                                    binaryMessenger: messenger)
    transcriptionChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "extractWav":
        let args = call.arguments as? [String: Any]
        guard let sourcePath = args?["sourcePath"] as? String,
              let outPath = args?["outPath"] as? String else {
          result(FlutterError(code: "ARGS", message: "sourcePath and outPath are required", details: nil))
          return
        }
        let start = (args?["startSeconds"] as? Double) ?? 0
        let dur = (args?["durationSeconds"] as? Double) ?? 0
        DispatchQueue.global(qos: .userInitiated).async {
          let ok = AudioWindowExtractor.extractWav(
            sourcePath: sourcePath, startSeconds: start, durationSeconds: dur, outPath: outPath)
          DispatchQueue.main.async { result(ok) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    let widgetChannel = FlutterMethodChannel(name: "com.absorb.widget",
                                               binaryMessenger: messenger)
    self.widgetChannel = widgetChannel
    widgetChannel.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "logReady":
        // Dart's log listener is live - flush everything buffered since
        // launch, stamped with seconds-after-launch so timing survives the
        // batch delivery.
        guard let self else { result(true); return }
        self.dartLogReady = true
        let pending = self.pendingNativeLogs
        self.pendingNativeLogs = []
        for (uptime, line) in pending {
          let stamp = String(format: "%.1f", uptime - self.launchUptime)
          self.widgetChannel?.invokeMethod("log", arguments: ["msg": "[+\(stamp)s] \(line)"])
        }
        result(true)
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

      case "reclaimNowPlaying":
        // Something else may have taken the Now Playing slot while Absorb sat
        // paused. Activating the session and republishing metadata is not
        // enough to get it back - only rendered audio moves the slot - so the
        // reassert goes through the primer rather than doing it in Dart.
        let reclaimReason = args?["reason"] as? String ?? "unknown"
        result(NowPlayingPrimer.reclaim(reason: reclaimReason))

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

/// Extracts a time window of an audiobook and exports it as an AAC .m4a clip
/// via AVAssetExportSession, which copies the source's artwork so the clip keeps
/// the book cover. iOS can't reliably export from a remote URL, so a streamed
/// book is fetched to a temp file in Dart first and handed in as a local path -
/// the native side here always works on a local file.
enum AudioClipExporter {
  static func exportM4a(
    source: String,
    isLocal: Bool,
    headers: [String: String]?,
    startSeconds: Double,
    durationSeconds: Double,
    outPath: String,
    completion: @escaping (Bool, String?) -> Void
  ) {
    let asset: AVURLAsset
    if isLocal {
      asset = AVURLAsset(url: URL(fileURLWithPath: source))
    } else {
      guard let url = URL(string: source) else {
        completion(false, "bad url")
        return
      }
      var options: [String: Any] = [:]
      if let headers = headers, !headers.isEmpty {
        options["AVURLAssetHTTPHeaderFieldsKey"] = headers
      }
      asset = AVURLAsset(url: url, options: options)
    }

    let outURL = URL(fileURLWithPath: outPath)
    try? FileManager.default.createDirectory(
      at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    // AVAssetExportSession refuses to overwrite an existing file.
    try? FileManager.default.removeItem(at: outURL)

    guard let export = AVAssetExportSession(
      asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
      completion(false, "could not create export session")
      return
    }
    export.outputURL = outURL
    export.outputFileType = .m4a
    let start = CMTime(seconds: max(0, startSeconds), preferredTimescale: 600)
    let duration = CMTime(seconds: max(1, durationSeconds), preferredTimescale: 600)
    export.timeRange = CMTimeRange(start: start, duration: duration)

    export.exportAsynchronously {
      switch export.status {
      case .completed:
        completion(true, nil)
      default:
        let message = export.error?.localizedDescription ?? "status \(export.status.rawValue)"
        try? FileManager.default.removeItem(at: outURL)
        completion(false, message)
      }
    }
  }
}

/// Ebook reader page turns via the physical volume keys. Observes the audio
/// session's outputVolume; a press away from the baseline fires a direction,
/// then the level is snapped back through a hidden MPVolumeView slider (whose
/// presence in the window also suppresses the system volume HUD). The user's
/// real volume is saved on start and restored on stop.
private final class VolumeKeyWatcher {
  private var observation: NSKeyValueObservation?
  private var volumeView: MPVolumeView?
  private var baseline: Float = 0.5
  private var savedVolume: Float?

  var onPressed: ((String) -> Void)?

  func start() {
    guard observation == nil else { return }
    let session = AVAudioSession.sharedInstance()
    try? session.setActive(true)

    let vv = MPVolumeView(frame: CGRect(x: -3000, y: -3000, width: 1, height: 1))
    vv.clipsToBounds = true
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let host = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
      ?? scenes.flatMap { $0.windows }.first
    host?.addSubview(vv)
    volumeView = vv

    savedVolume = session.outputVolume
    // Snap the baseline to iOS's 1/16 volume steps, away from the extremes so
    // both directions stay detectable at min/max volume.
    baseline = (min(max(session.outputVolume, 0.25), 0.75) * 16).rounded() / 16

    // Give the volume view a beat to land in the hierarchy before its slider
    // will accept a value, then normalize to the baseline.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
      guard let self, self.observation != nil else { return }
      self.setSystemVolume(self.baseline)
    }

    observation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
      guard let self, let new = change.newValue else { return }
      // Our own baseline resets land exactly on the baseline - ignore them.
      if abs(new - self.baseline) < 0.01 { return }
      let direction = new > self.baseline ? "up" : "down"
      DispatchQueue.main.async {
        self.onPressed?(direction)
        self.setSystemVolume(self.baseline)
      }
    }
  }

  func stop() {
    guard observation != nil else { return }
    observation?.invalidate()
    observation = nil
    if let saved = savedVolume { setSystemVolume(saved) }
    savedVolume = nil
    let vv = volumeView
    volumeView = nil
    // Keep the view alive briefly so the restore above goes through.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      vv?.removeFromSuperview()
    }
  }

  private func setSystemVolume(_ value: Float) {
    guard let slider = volumeView?.subviews.compactMap({ $0 as? UISlider }).first else { return }
    slider.value = value
  }
}
/// Decodes a time window of a compressed audio file into the 16kHz mono 16-bit
/// PCM WAV that whisper.cpp requires. AVAssetReader performs the sample-rate
/// conversion and downmix via its output settings, so no ffmpeg is needed.
/// Used by the opt-in bookmark transcription feature.
enum AudioWindowExtractor {
  static func extractWav(sourcePath: String, startSeconds: Double, durationSeconds: Double, outPath: String) -> Bool {
    let asset = AVURLAsset(url: URL(fileURLWithPath: sourcePath))
    guard let track = asset.tracks(withMediaType: .audio).first else {
      NSLog("[Transcribe] no audio track in %@", sourcePath)
      return false
    }

    let reader: AVAssetReader
    do {
      reader = try AVAssetReader(asset: asset)
    } catch {
      NSLog("[Transcribe] reader init failed: %@", error.localizedDescription)
      return false
    }

    let start = CMTime(seconds: max(0, startSeconds), preferredTimescale: 1000)
    let dur = CMTime(seconds: max(0, durationSeconds), preferredTimescale: 1000)
    reader.timeRange = CMTimeRange(start: start, duration: dur)

    let settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVSampleRateKey: 16000,
      AVNumberOfChannelsKey: 1,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVLinearPCMIsBigEndianKey: false,
      AVLinearPCMIsNonInterleaved: false,
    ]
    let output = AVAssetReaderTrackOutput(track: track, outputSettings: settings)
    output.alwaysCopiesSampleData = false
    guard reader.canAdd(output) else { return false }
    reader.add(output)
    guard reader.startReading() else {
      NSLog("[Transcribe] startReading failed: %@", reader.error?.localizedDescription ?? "nil")
      return false
    }

    var pcm = Data()
    while reader.status == .reading {
      guard let sample = output.copyNextSampleBuffer() else { break }
      if let block = CMSampleBufferGetDataBuffer(sample) {
        let length = CMBlockBufferGetDataLength(block)
        if length > 0 {
          var chunk = Data(count: length)
          chunk.withUnsafeMutableBytes { (ptr: UnsafeMutableRawBufferPointer) in
            if let base = ptr.baseAddress {
              _ = CMBlockBufferCopyDataBytes(block, atOffset: 0, dataLength: length, destination: base)
            }
          }
          pcm.append(chunk)
        }
      }
      CMSampleBufferInvalidate(sample)
    }

    if reader.status == .failed {
      NSLog("[Transcribe] reader failed: %@", reader.error?.localizedDescription ?? "nil")
      return false
    }
    if pcm.isEmpty { return false }
    return writeWav(path: outPath, pcm16le: pcm, sampleRate: 16000)
  }

  private static func writeWav(path: String, pcm16le: Data, sampleRate: Int) -> Bool {
    let channels = 1
    let bitsPerSample = 16
    let byteRate = sampleRate * channels * bitsPerSample / 8
    let blockAlign = channels * bitsPerSample / 8
    let dataSize = pcm16le.count

    var header = Data()
    func appendU32(_ v: UInt32) { var x = v.littleEndian; header.append(Data(bytes: &x, count: 4)) }
    func appendU16(_ v: UInt16) { var x = v.littleEndian; header.append(Data(bytes: &x, count: 2)) }

    header.append("RIFF".data(using: .ascii)!)
    appendU32(UInt32(36 + dataSize))
    header.append("WAVE".data(using: .ascii)!)
    header.append("fmt ".data(using: .ascii)!)
    appendU32(16)                       // PCM fmt chunk size
    appendU16(1)                        // audio format = PCM
    appendU16(UInt16(channels))
    appendU32(UInt32(sampleRate))
    appendU32(UInt32(byteRate))
    appendU16(UInt16(blockAlign))
    appendU16(UInt16(bitsPerSample))
    header.append("data".data(using: .ascii)!)
    appendU32(UInt32(dataSize))

    var out = header
    out.append(pcm16le)
    do {
      try out.write(to: URL(fileURLWithPath: path))
      return true
    } catch {
      NSLog("[Transcribe] wav write failed: %@", error.localizedDescription)
      return false
    }
  }
}
