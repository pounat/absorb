import AVFoundation
import Foundation

/// Lets Absorb play alongside other apps' audio (music, a video) instead of
/// interrupting it. iOS hands the lock screen, Control Center and headset
/// controls only to a session that does not mix, so while Absorb mixes those
/// controls stay with the other app.
///
/// Every place that sets the session category goes through [apply], so the
/// launch setup, the playback paths, the Now Playing primer and the widget
/// intents agree. Dart asks for the same decision (`audioMixDecision` on the
/// `com.absorb.audio_mix` channel) before its audio_session configure, which
/// runs right before Dart activates the session and would otherwise put the
/// exclusive category back.
public enum AbsorbAudioMix {
  public enum Mode: String {
    /// Never mix: starting a book interrupts other audio.
    case off
    /// Mix only when another app is already playing as the book starts.
    case auto
    /// Always mix.
    case always
  }

  private static let modeKey = "audio_mix_mode"
  private static let duckKey = "audio_mix_duck"

  /// Whether Absorb's own player is producing audio. The host app wires this
  /// up at launch, since the engine lives outside this package.
  public static var ownAudioIsPlaying: () -> Bool = { false }

  public static var mode: Mode {
    Mode(rawValue: UserDefaults(suiteName: absorbAppGroup)?.string(forKey: modeKey) ?? "") ?? .off
  }

  /// Turn the other app down while the book plays.
  public static var duckOthers: Bool {
    UserDefaults(suiteName: absorbAppGroup)?.bool(forKey: duckKey) ?? false
  }

  public static func store(mode: Mode, duckOthers: Bool) {
    let defaults = UserDefaults(suiteName: absorbAppGroup)
    defaults?.set(mode.rawValue, forKey: modeKey)
    defaults?.set(duckOthers, forKey: duckKey)
  }

  public static func shouldMix(_ session: AVAudioSession = .sharedInstance()) -> Bool {
    switch mode {
    case .off:
      return false
    case .always:
      return true
    case .auto:
      // Keep mixing while the book plays. Turning exclusive mid-book because
      // the other app happened to pause would let its next play cut the book off.
      if session.categoryOptions.contains(.mixWithOthers), ownAudioIsPlaying() {
        return true
      }
      return session.isOtherAudioPlaying
    }
  }

  /// Sets the category for the current decision and returns whether the
  /// session now mixes. A category that already matches is left alone, since
  /// re-setting one makes iOS post a route change.
  @discardableResult
  public static func apply(_ session: AVAudioSession = .sharedInstance()) throws -> Bool {
    let mix = shouldMix(session)
    // Apple allows no category options under the long-form route policy, so
    // mixing has to give that policy up.
    let policy: AVAudioSession.RouteSharingPolicy = mix ? .default : .longFormAudio
    // duckOthers implies mixWithOthers; naming both keeps the comparison with
    // what iOS reports back exact.
    let options: AVAudioSession.CategoryOptions =
      mix ? (duckOthers ? [.mixWithOthers, .duckOthers] : [.mixWithOthers]) : []
    if session.category == .playback, session.mode == .spokenAudio,
       session.routeSharingPolicy == policy, session.categoryOptions == options {
      return mix
    }
    try session.setCategory(.playback, mode: .spokenAudio, policy: policy, options: options)
    NSLog("[AudioMix] category set: mix=%@ duck=%@ (mode %@)",
          mix ? "yes" : "no", options.contains(.duckOthers) ? "yes" : "no", mode.rawValue)
    return mix
  }

  /// A ducking session keeps the other app turned down for as long as it is
  /// active, so on pause it goes inactive to hand that volume back.
  public static func releaseDuck(_ session: AVAudioSession = .sharedInstance(), retry: Bool = true) {
    guard session.categoryOptions.contains(.duckOthers), !ownAudioIsPlaying() else { return }
    do {
      try session.setActive(false, options: .notifyOthersOnDeactivation)
    } catch {
      // The player's output can take a moment to wind down after pause().
      NSLog("[AudioMix] releasing the duck failed: %@", error.localizedDescription)
      if retry {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          releaseDuck(session, retry: false)
        }
      }
    }
  }
}
