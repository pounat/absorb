import AppIntents
import AVFoundation
import Foundation

/// App group used by the host app, the widget extension, and these
/// intents. Hardcoded so the package has no setup at the call site.
public let absorbAppGroup = "group.com.barnabas.absorb"

// MARK: - Helpers

/// Posts a Darwin notification visible to the main app process. Lives in
/// the package so widget intents (and any future Siri/Live Activity
/// intents) share the same wakeup mechanism.
public func postAbsorbDarwinNotification(_ name: String) {
  NSLog("[WidgetDebug] postDarwinNotification: %@", name)
  let center = CFNotificationCenterGetDarwinNotifyCenter()
  CFNotificationCenterPostNotification(center, CFNotificationName(name as CFString), nil, nil, true)
}

// MARK: - Audio ownership (#285)
//
// iOS can end up with two processes of the app alive at once: a widget
// AudioPlaybackIntent can launch a headless background process, and a later
// foreground launch can be a separate process. Both boot a full Flutter
// engine, so every shared flag used to be written by both sides and a single
// widget tap could actuate playback in both processes - two overlapping
// streams of the same book.
//
// The arbitration is now pid-based: `audio_owner_pid` names the one process
// allowed to act on widget taps, and each process's Flutter proves it is
// alive via its own pid-scoped `flutter_alive_at_<pid>` heartbeat, so no
// process can vouch for (or impersonate) another.

/// Pid of the process that currently owns audio, or 0 when never claimed.
public func absorbAudioOwnerPid() -> Int {
  return UserDefaults(suiteName: absorbAppGroup)?.integer(forKey: "audio_owner_pid") ?? 0
}

/// True when `pid`'s Flutter engine wrote its heartbeat within the last 30s.
/// The key is pid-scoped so a stray background process's heartbeat can't
/// make another process's Flutter look alive.
public func absorbFlutterAlive(pid: Int) -> Bool {
  guard pid > 0,
        let aliveAt = UserDefaults(suiteName: absorbAppGroup)?
          .object(forKey: "flutter_alive_at_\(pid)") as? Int
  else { return false }
  let ageMs = Int(Date().timeIntervalSince1970 * 1000) - aliveAt
  return ageMs >= 0 && ageMs < 30_000
}

/// Stamp that audio actuation is happening right now - a widget play intent
/// fired, or the native engine is playing. The widget trusts a stored
/// "playing" flag only while some liveness signal is fresh, and the Flutter
/// heartbeat can lag by many seconds when a native play wakes a suspended
/// process - without this stamp the play/pause icon didn't flip until the
/// heartbeat caught up.
public func absorbStampAudioActivity() {
  UserDefaults(suiteName: absorbAppGroup)?.set(
    Int(Date().timeIntervalSince1970 * 1000), forKey: "audio_active_at")
}

/// True when audio actuation was stamped within the last 150s (the native
/// core re-stamps at least every 60s while it drives playback).
public func absorbAudioActivityFresh() -> Bool {
  guard let at = UserDefaults(suiteName: absorbAppGroup)?
          .object(forKey: "audio_active_at") as? Int
  else { return false }
  let ageMs = Int(Date().timeIntervalSince1970 * 1000) - at
  return ageMs >= 0 && ageMs < 150_000
}

/// Claim audio ownership for this process unless the current owner's Flutter
/// is verifiably alive in another process. Called from each widget intent's
/// perform(): iOS chose this process to handle a user-initiated audio action,
/// which is as authoritative as a foreground scene - but only when the
/// recorded owner is dead (app killed) or has gone quiet (suspended while
/// paused). A live owner elsewhere keeps ownership and its process actuates
/// via the Darwin broadcast instead.
public func absorbClaimOwnershipIfOwnerDead() {
  let me = Int(getpid())
  let owner = absorbAudioOwnerPid()
  if owner == me { return }
  if absorbFlutterAlive(pid: owner) { return }
  UserDefaults(suiteName: absorbAppGroup)?.set(me, forKey: "audio_owner_pid")
  NSLog("[WidgetDebug] intent claimed audio ownership: pid \(me) (previous owner \(owner) not alive)")
}

/// Activate the system audio session from inside an AudioPlaybackIntent's
/// perform(). AVAudioSession is system-wide, so flipping it on here keeps
/// it active by the time the host app's audio engine runs play() a few
/// hundred ms later. Without this, the iOS-granted "audio playback"
/// privilege from AudioPlaybackIntent expires before the Darwin
/// notification reaches Flutter and the host app's setActive(true)
/// silently fails.
public func activateAbsorbAudioSession() {
  let session = AVAudioSession.sharedInstance()
  do {
    try AbsorbAudioMix.apply(session)
    try session.setActive(true)
    NSLog("[WidgetDebug] AVAudioSession activated in widget perform()")
  } catch {
    NSLog("[WidgetDebug] AVAudioSession activate error: %@", error.localizedDescription)
  }
}

// MARK: - App Intents
//
// AudioPlaybackIntent (iOS 17+) tells the system this intent controls
// audio playback. Combined with @Dependency on AbsorbPlayerCoreProtocol,
// iOS launches the host app's process (where the dependency is
// registered in AppDelegate) to run perform() rather than running it in
// the widget extension's sandbox where AbsorbPlayerCore isn't reachable.
//
// The intents live in this shared package (rather than the widget
// extension target) so both Runner and NowPlayingWidgetExtension see the
// same Swift type. AppDependencyManager.shared.add() in the host app is
// keyed by Swift type identity, and types declared only in the widget
// extension target wouldn't match anything the host app registered.
//
// Each intent is marked iOS 16+ since AppIntents itself is iOS 16+.
// Runner deploys back to iOS 15; the widget extension is iOS 17. Runner
// guards its use of these symbols with `if #available(iOS 16, *)`.

@available(iOS 16.0, *)
public struct AbsorbSkipBackIntent: AudioPlaybackIntent {
  public static let title: LocalizedStringResource = "Skip Back"
  public static let description = IntentDescription("Skip backward in the current audiobook.")
  public static let openAppWhenRun = false

  @Dependency
  private var core: AbsorbPlayerCoreProtocol

  public init() {}

  public func perform() async throws -> some IntentResult {
    core.log("[NativeCore] SkipBackIntent.perform fired (host process)")
    absorbClaimOwnershipIfOwnerDead()
    activateAbsorbAudioSession()
    let seconds = UserDefaults(suiteName: absorbAppGroup)?
      .integer(forKey: "widget_skip_back")
    core.skipBackward(seconds: (seconds ?? 0) > 0 ? seconds! : 10)
    postAbsorbDarwinNotification("com.barnabas.absorb.widget.skipBack")
    return .result()
  }
}

@available(iOS 16.0, *)
public struct AbsorbPlayPauseIntent: AudioPlaybackIntent {
  public static let title: LocalizedStringResource = "Play or Pause"
  public static let description = IntentDescription("Toggle audiobook playback.")
  public static let openAppWhenRun = false

  @Dependency
  private var core: AbsorbPlayerCoreProtocol

  public init() {}

  public func perform() async throws -> some IntentResult {
    core.log("[NativeCore] PlayPauseIntent.perform fired (host process)")
    absorbClaimOwnershipIfOwnerDead()
    // Instant icon feedback: predict what the toggle will do rather than
    // blindly inverting the stored flag (which is stale after a force-kill).
    // Whichever side actually actuates writes the real state right after.
    let willPlay = core.willPlayAfterToggle()
    UserDefaults(suiteName: absorbAppGroup)?.set(willPlay, forKey: "widget_is_playing")
    if willPlay { absorbStampAudioActivity() }
    core.log("[NativeCore]   predicted willPlay=\(willPlay)")
    activateAbsorbAudioSession()
    core.toggle()
    postAbsorbDarwinNotification("com.barnabas.absorb.widget.playPause")
    return .result()
  }
}

@available(iOS 16.0, *)
public struct AbsorbSkipForwardIntent: AudioPlaybackIntent {
  public static let title: LocalizedStringResource = "Skip Forward"
  public static let description = IntentDescription("Skip forward in the current audiobook.")
  public static let openAppWhenRun = false

  @Dependency
  private var core: AbsorbPlayerCoreProtocol

  public init() {}

  public func perform() async throws -> some IntentResult {
    core.log("[NativeCore] SkipForwardIntent.perform fired (host process)")
    absorbClaimOwnershipIfOwnerDead()
    activateAbsorbAudioSession()
    let seconds = UserDefaults(suiteName: absorbAppGroup)?
      .integer(forKey: "widget_skip_forward")
    core.skipForward(seconds: (seconds ?? 0) > 0 ? seconds! : 30)
    postAbsorbDarwinNotification("com.barnabas.absorb.widget.skipForward")
    return .result()
  }
}
