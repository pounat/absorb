import AVFoundation
import MediaPlayer
import UIKit

/// Claims the iOS Now Playing slot at launch, so a headset play button reaches
/// Absorb before anything has been played in this process.
///
/// iOS hands remote control commands to whichever app it considers "now
/// playing", and an app only becomes a candidate once it has an active audio
/// session AND has actually rendered audio. Absorb used to do neither until the
/// user pressed play inside the app, which is why a headset press after a cold
/// launch went nowhere - or worse, to another device on a multipoint headset.
/// Users reported having to pull the phone out, open Absorb and press play
/// before their headphones would work at all.
///
/// Two parts, both needed:
/// - activate the session, which the app deliberately avoided at launch because
///   it interrupts other apps' audio. That only happens when something else is
///   actually playing, so the guard below is what makes it safe rather than
///   skipping it entirely.
/// - render half a second of silence, because an active session that never
///   produces audio does not reliably win the slot.
enum NowPlayingPrimer {
  static var logSink: ((String) -> Void)?

  private static let appGroup = "group.com.barnabas.absorb"

  /// The silent player has to outlive this function or it deallocates before
  /// the blip finishes and the claim never lands.
  private static var blipPlayer: AVPlayer?

  /// A 44-byte WAV header with no samples: enough for iOS to count as playback,
  /// too short to be heard even if the volume guard failed.
  private static let silentWav =
    "data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA="

  /// In the car the controls have to reach us even if something else is
  /// playing, so CarPlay overrides the other-audio guard.
  private static func isCarPlayConnected(_ session: AVAudioSession) -> Bool {
    session.currentRoute.outputs.contains { $0.portType == .carAudio }
  }

  /// Publish what the last-played book was and take the slot for it. Reads the
  /// app-group stash the widget already keeps up to date, so this needs neither
  /// the Flutter engine nor the network - it runs before either is ready.
  static func primeAtLaunch() {
    let session = AVAudioSession.sharedInstance()

    // Someone else is playing. Claiming here would interrupt them the moment
    // Absorb opens, which is exactly what the user did not ask for. CarPlay is
    // the exception: in the car the controls have to reach us regardless.
    let otherAudio = session.isOtherAudioPlaying
    let shouldSilence = session.secondaryAudioShouldBeSilencedHint
    if (otherAudio || shouldSilence), !isCarPlayConnected(session) {
      logSink?(
        "[NowPlayingPrimer] skipped, other audio is playing "
          + "(isOtherAudioPlaying=\(otherAudio) silenceHint=\(shouldSilence))")
      return
    }

    let defaults = UserDefaults(suiteName: appGroup)
    guard let itemId = defaults?.string(forKey: "np_item_id"), !itemId.isEmpty else {
      logSink?("[NowPlayingPrimer] skipped, nothing has been played on this device yet")
      return
    }

    // Launched by the widget to start playing, so audio is already on its way.
    // Priming now would stamp a paused, stale state over the real one.
    if defaults?.bool(forKey: "widget_is_playing") == true {
      logSink?("[NowPlayingPrimer] skipped, playback is already running")
      return
    }

    do {
      try session.setCategory(.playback, mode: .spokenAudio, policy: .longFormAudio)
      try session.setActive(true)
    } catch {
      logSink?("[NowPlayingPrimer] session activate failed: \(error.localizedDescription)")
      return
    }

    let title = defaults?.string(forKey: "np_title")
      ?? defaults?.string(forKey: "widget_title") ?? ""
    let author = defaults?.string(forKey: "np_author")
      ?? defaults?.string(forKey: "widget_author") ?? ""
    let coverPath = defaults?.string(forKey: "np_cover_path")
      ?? defaults?.string(forKey: "widget_cover_path")
    let elapsed = defaults?.double(forKey: "np_position_s") ?? 0
    let duration = defaults?.double(forKey: "np_total_s") ?? 0

    var info: [String: Any] = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: author,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
      // Paused: nothing is playing yet, we are only claiming the controls.
      MPNowPlayingInfoPropertyPlaybackRate: 0.0,
      MPNowPlayingInfoPropertyDefaultPlaybackRate: 1.0,
      MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
      MPMediaItemPropertyMediaType: MPMediaType.audioBook.rawValue,
    ]
    if duration > 0 {
      info[MPMediaItemPropertyPlaybackDuration] = duration
    }
    if let coverPath, let img = UIImage(contentsOfFile: coverPath) {
      info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info

    guard let url = URL(string: silentWav) else { return }
    let player = AVPlayer(url: url)
    player.allowsExternalPlayback = false
    player.volume = 0
    blipPlayer = player
    player.play()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      blipPlayer = nil
    }

    logSink?(
      "[NowPlayingPrimer] claimed Now Playing for \"\(title)\" at "
        + "\(Int(elapsed))s (paused)")
  }
}
