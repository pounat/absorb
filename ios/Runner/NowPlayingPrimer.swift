import AVFoundation

/// Takes the iOS Now Playing slot back for Absorb mid-session, so headset
/// controls keep reaching this app after something else played.
///
/// iOS hands remote control commands to whichever app it considers "now
/// playing", and an app only becomes a candidate once it has an active audio
/// session AND has actually rendered audio. So the reclaim is two parts, both
/// needed:
/// - activate the session, guarded so it never interrupts another app that is
///   actually playing (CarPlay excepted - in the car the controls must reach
///   us regardless).
/// - render half a second of silence, because an active session that never
///   produces audio does not reliably win the slot. Build 249 activated and
///   published metadata without rendering, and lost the slot twice in the
///   field; 251 added real samples and held it. Anything that wants the slot
///   back has to come through here for that reason.
///
/// This used to also claim the slot at every launch from the app-group stash,
/// so a headset press worked before the user ever pressed play in the app -
/// that never worked reliably in the field and put a phantom paused book on
/// the lock screen at every app open, so it was removed. Until the user
/// plays, Absorb makes no claim.
enum NowPlayingPrimer {
  static var logSink: ((String) -> Void)?

  /// The silent player has to outlive this function or it deallocates before
  /// the blip finishes and the claim never lands.
  private static var blipPlayer: AVAudioPlayer?

  /// Logs whether the blip actually rendered. play() returning true only means
  /// the request was accepted; this is the ground truth.
  private final class BlipDelegate: NSObject, AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
      DispatchQueue.main.async {
        NowPlayingPrimer.logSink?("[NowPlayingPrimer] blip finished (rendered=\(flag))")
        NowPlayingPrimer.blipPlayer = nil
      }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
      DispatchQueue.main.async {
        NowPlayingPrimer.logSink?(
          "[NowPlayingPrimer] blip decode error: \(error?.localizedDescription ?? "unknown")")
        NowPlayingPrimer.blipPlayer = nil
      }
    }
  }

  private static let blipDelegate = BlipDelegate()

  /// True silence as 16-bit mono 8kHz PCM. The samples must exist: a
  /// header-only WAV with an empty data chunk renders nothing, and iOS does
  /// not hand over the Now Playing slot for audio that never reached the
  /// mixer - the whole point of the blip.
  private static func makeSilentWav(durationMs: Int) -> Data {
    let sampleRate = 8000
    let dataSize = sampleRate * durationMs / 1000 * 2
    var wav = Data(capacity: 44 + dataSize)
    func u32(_ v: UInt32) { var x = v.littleEndian; wav.append(Data(bytes: &x, count: 4)) }
    func u16(_ v: UInt16) { var x = v.littleEndian; wav.append(Data(bytes: &x, count: 2)) }
    wav.append("RIFF".data(using: .ascii)!)
    u32(UInt32(36 + dataSize))
    wav.append("WAVE".data(using: .ascii)!)
    wav.append("fmt ".data(using: .ascii)!)
    u32(16)                          // PCM fmt chunk size
    u16(1)                           // audio format = PCM
    u16(1)                           // channels
    u32(UInt32(sampleRate))
    u32(UInt32(sampleRate * 2))      // byte rate
    u16(2)                           // block align
    u16(16)                          // bits per sample
    wav.append("data".data(using: .ascii)!)
    u32(UInt32(dataSize))
    wav.append(Data(count: dataSize))
    return wav
  }

  /// In the car the controls have to reach us even if something else is
  /// playing, so CarPlay overrides the other-audio guard.
  private static func isCarPlayConnected(_ session: AVAudioSession) -> Bool {
    session.currentRoute.outputs.contains { $0.portType == .carAudio }
  }

  /// Take the slot back mid-session, after something else may have won it: the
  /// user opened another app that played audio, an interruption came and went
  /// while Absorb sat suspended, or the headphones were stowed. Metadata is
  /// already live in audio_service by this point, so nothing is republished
  /// here - only the activation and the blip, which is the part that actually
  /// moves the slot. Returns whether the blip started; the "blip finished
  /// (rendered=)" line is the ground truth for whether it landed.
  @discardableResult
  static func reclaim(reason: String) -> Bool {
    return claim(reason: reason)
  }

  @discardableResult
  private static func claim(reason: String) -> Bool {
    let session = AVAudioSession.sharedInstance()

    // A blip already on its way is the same claim. Starting a second one
    // replaces the player and deallocates the first mid-render, so neither
    // lands - reasserts from different triggers can arrive within a few
    // hundred milliseconds of each other.
    if blipPlayer != nil {
      logSink?("[NowPlayingPrimer] \(reason): skipped, a claim is already in flight")
      return false
    }

    // Our own engine is already playing (a headset press launched the process
    // and the native core streamed from the stash before Flutter came up).
    // The other-audio check below can't see it - isOtherAudioPlaying only
    // reports OTHER apps - and it already owns the slot; blipping over live
    // audio has nothing to win.
    if AbsorbAudioEngine.shared.isPlaying {
      logSink?("[NowPlayingPrimer] \(reason): skipped, our own engine is playing")
      return false
    }

    // Someone else is playing. Claiming here would interrupt them the moment
    // Absorb opens, which is exactly what the user did not ask for. CarPlay is
    // the exception: in the car the controls have to reach us regardless.
    let otherAudio = session.isOtherAudioPlaying
    let shouldSilence = session.secondaryAudioShouldBeSilencedHint
    if (otherAudio || shouldSilence), !isCarPlayConnected(session) {
      logSink?(
        "[NowPlayingPrimer] \(reason): skipped, other audio is playing "
          + "(isOtherAudioPlaying=\(otherAudio) silenceHint=\(shouldSilence))")
      return false
    }

    do {
      // Re-setting a category that already matches makes iOS emit a route
      // change, which is log noise on every foreground reassert.
      if session.category != .playback {
        try session.setCategory(.playback, mode: .spokenAudio, policy: .longFormAudio)
      }
      try session.setActive(true)
    } catch {
      logSink?(
        "[NowPlayingPrimer] \(reason): session activate failed: \(error.localizedDescription)")
      return false
    }

    do {
      let player = try AVAudioPlayer(data: makeSilentWav(durationMs: 600))
      player.volume = 0
      player.delegate = blipDelegate
      blipPlayer = player
      let started = player.play()
      logSink?("[NowPlayingPrimer] reclaimed Now Playing (\(reason), blip started=\(started))")
      DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        if blipPlayer != nil {
          logSink?("[NowPlayingPrimer] blip never finished - releasing")
          blipPlayer = nil
        }
      }
      return started
    } catch {
      logSink?("[NowPlayingPrimer] \(reason): blip init failed: \(error.localizedDescription)")
      return false
    }
  }
}
