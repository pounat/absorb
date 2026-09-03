import AbsorbPlayerCore
import AVFoundation
import Foundation
import MediaPlayer
import UIKit
import WidgetKit

/// Controller that drives audiobook playback while Flutter is suspended.
///
/// It does NOT own an AVPlayer. All audio runs through the single process-wide
/// `AbsorbAudioEngine.shared`, which also serves in-app playback and survives
/// Flutter suspension. So a widget play just resumes the already-loaded engine
/// rather than starting a second AVPlayer - that's what made bug #285 possible
/// (two concurrent streams from the same book).
///
/// State source: app group `np_*` keys written by `home_widget_service.dart`.
/// Hand-off: the pid-scoped `flutter_alive_at_<pid>` heartbeat - if THIS
/// process's Flutter wrote it recently, Flutter is in charge and native bails
/// on every entry point. Pid-scoped because a stray background process runs
/// its own full Flutter engine, and a shared heartbeat let it make every
/// process think Flutter was alive (#285).
final class AbsorbPlayerCore: NSObject, AbsorbPlayerCoreProtocol, @unchecked Sendable {
  static let shared = AbsorbPlayerCore()

  static var logSink: ((String) -> Void)?

  private static let appGroup = "group.com.barnabas.absorb"

  private let queue = DispatchQueue(label: "com.barnabas.absorb.nativecore")

  // Bookkeeping for server push + Now Playing. The actual audio state lives in
  // AbsorbAudioEngine.shared; these just mirror what book we last targeted.
  private var _currentItemId: String?
  private var _currentEpisodeId: String?

  private var _commandsConfigured = false

  // Lock screen skip amounts, mirrored from Dart. They start on the same
  // defaults as PlayerSettings so the buttons are right before Dart pushes
  // anything, then follow the user's setting (and per-library override).
  private var _skipForwardSec = 30
  private var _skipBackwardSec = 10

  // Server sync timer (separate from the engine's position observer).
  private var _serverSyncTimer: Timer?
  private static let serverSyncIntervalSec: TimeInterval = 60.0

  private override init() {
    super.init()
    emit("[NativeCore] init - host app process is alive")
  }

  // MARK: - Public API (AbsorbPlayerCoreProtocol)

  func play() {
    queue.async { [weak self] in
      guard let self = self else { return }
      if self.flutterIsAlive() {
        self.emit("[NativeCore] play(): Flutter is alive, bailing")
        return
      }
      guard self.ensureLoaded() else {
        self.emit("[NativeCore] play(): no engine source loaded")
        return
      }
      self.activateAudioSession()
      AbsorbAudioEngine.shared.play()
      self.emit("[NativeCore] play(): global=\(self.globalPosition())s")
      self.startServerSyncTimer()
      self.updateNowPlayingInfo(rate: Double(self.currentSpeed()))
      self.syncWidgetState()
    }
  }

  func pause() {
    queue.async { [weak self] in
      guard let self = self else { return }
      if self.flutterIsAlive() {
        self.emit("[NativeCore] pause(): Flutter is alive, bailing")
        return
      }
      AbsorbAudioEngine.shared.pause()
      self.emit("[NativeCore] pause(): pos=\(self.globalPosition())s")
      self.savePosition()
      self.pushProgressToServer()
      self.stopServerSyncTimer()
      self.updateNowPlayingInfo(rate: 0)
      self.syncWidgetState()
    }
  }

  func toggle() {
    queue.async { [weak self] in
      guard let self = self else { return }
      if self.flutterIsAlive() {
        self.emit("[NativeCore] toggle(): Flutter is alive, bailing")
        return
      }
      guard self.ensureLoaded() else {
        self.emit("[NativeCore] toggle(): no engine source loaded")
        return
      }
      if AbsorbAudioEngine.shared.isPlaying {
        AbsorbAudioEngine.shared.pause()
        self.emit("[NativeCore] toggle(): paused at \(self.globalPosition())s")
        self.savePosition()
        self.pushProgressToServer()
        self.stopServerSyncTimer()
        self.updateNowPlayingInfo(rate: 0)
      } else {
        self.activateAudioSession()
        AbsorbAudioEngine.shared.play()
        self.emit("[NativeCore] toggle(): playing global=\(self.globalPosition())s")
        self.startServerSyncTimer()
        self.updateNowPlayingInfo(rate: Double(self.currentSpeed()))
      }
      self.syncWidgetState()
    }
  }

  func skipForward(seconds: Int) {
    queue.async { [weak self] in
      guard let self = self else { return }
      if self.flutterIsAlive() {
        self.emit("[NativeCore] skipForward(\(seconds)): Flutter is alive, bailing")
        return
      }
      guard self.ensureLoaded() else { return }
      let now = self.globalPosition()
      let dur = self.totalDuration()
      let target = min(dur > 0 ? dur : .greatestFiniteMagnitude, now + Double(seconds))
      self.emit("[NativeCore] skipForward(\(seconds)s): \(now)s -> \(target)s")
      self.seekToGlobal(target)
    }
  }

  func skipBackward(seconds: Int) {
    queue.async { [weak self] in
      guard let self = self else { return }
      if self.flutterIsAlive() {
        self.emit("[NativeCore] skipBackward(\(seconds)): Flutter is alive, bailing")
        return
      }
      guard self.ensureLoaded() else { return }
      let now = self.globalPosition()
      let target = max(0, now - Double(seconds))
      self.emit("[NativeCore] skipBackward(\(seconds)s): \(now)s -> \(target)s")
      self.seekToGlobal(target)
    }
  }

  func log(_ message: String) {
    emit(message)
  }

  // MARK: - Hand-off

  /// Another process (the foreground app) has claimed audio ownership. Stash our
  /// spot so the owner can resume from it, drop the now-playing flag, and stop
  /// the engine so we don't leave a second stream playing that the foreground
  /// app can't reach. This is the fix for two concurrent streams (#285): a
  /// widget play intent can start playback in a background process, and without
  /// this that stream keeps going after the app is reopened and the user presses
  /// play, leaving two overlapping streams from the same book.
  func yieldToForegroundOwner() {
    queue.async { [weak self] in
      guard let self = self else { return }
      guard AbsorbAudioEngine.shared.isLoaded || AbsorbAudioEngine.shared.isPlaying else {
        self.emit("[NativeCore] yieldToForegroundOwner: engine idle, nothing to stop")
        return
      }
      self.emit("[NativeCore] yieldToForegroundOwner: stopping at \(self.globalPosition())s so the foreground app can take over")
      self.savePosition()
      self.stopServerSyncTimer()
      AbsorbAudioEngine.shared.stop()
      self.syncWidgetState()
      // Relinquish Now Playing so iOS routes lock screen / Control Center
      // commands to the new owner instead of this stray process. A stale
      // entry here is what left Control Center greyed out while the other
      // process's audio kept going.
      DispatchQueue.main.async {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
      }
    }
  }

  private func flutterIsAlive() -> Bool {
    // Only THIS process's Flutter counts - the actions below run in-process,
    // so another process's live Flutter is irrelevant here.
    return absorbFlutterAlive(pid: Int(getpid()))
  }

  /// See AbsorbPlayerCoreProtocol. Runs the prediction on the core queue so
  /// engine state reads are consistent with any in-flight actuation.
  func willPlayAfterToggle() -> Bool {
    return queue.sync {
      let myPid = Int(getpid())
      if absorbFlutterAlive(pid: myPid) || absorbFlutterAlive(pid: absorbAudioOwnerPid()) {
        // A live Flutter (here or in the owning process) will do the toggle,
        // and it keeps the stored flag accurate - inverting it is safe.
        let stored = UserDefaults(suiteName: Self.appGroup)?.bool(forKey: "widget_is_playing") ?? false
        return !stored
      }
      if AbsorbAudioEngine.shared.isLoaded {
        return !AbsorbAudioEngine.shared.isPlaying
      }
      // Cold native start: ensureLoaded + play.
      return true
    }
  }

  // MARK: - State plumbing

  /// Make sure the shared engine holds the book the app group points at.
  ///
  /// Warm case: the engine is already on this book (`currentItemId` matches) -
  /// do nothing and adopt its live position. This is the common widget-resume
  /// path and is what keeps a single stream.
  ///
  /// Cold case: the engine has nothing (or a different book) loaded - build
  /// the source from app-group state and load it at the saved position.
  ///
  /// Returns false only when there's no playable source at all.
  @discardableResult
  private func ensureLoaded() -> Bool {
    let defaults = UserDefaults(suiteName: Self.appGroup)
    guard let itemId = defaults?.string(forKey: "np_item_id") else {
      emit("[NativeCore] ensureLoaded: no np_item_id in app group")
      return false
    }
    // '' is the stored form of "no episode" (NSUserDefaults can't hold null).
    let storedEpisodeId = defaults?.string(forKey: "np_episode_id")
    let episodeId = (storedEpisodeId?.isEmpty ?? true) ? nil : storedEpisodeId

    // Engine already holds this exact book: adopt it, no reload.
    if AbsorbAudioEngine.shared.currentItemId == itemId, AbsorbAudioEngine.shared.isLoaded {
      _currentItemId = itemId
      _currentEpisodeId = episodeId
      configureRemoteCommandsIfNeeded()
      emit("[NativeCore] ensureLoaded: engine already on \(itemId), adopting live playback")
      return true
    }

    let isDownloaded = defaults?.bool(forKey: "np_is_downloaded") ?? false
    let urls: [URL]
    let headers: [String: String]
    if isDownloaded,
       let pathsJson = defaults?.string(forKey: "np_audio_paths_json"),
       let pathsData = pathsJson.data(using: .utf8),
       let paths = try? JSONSerialization.jsonObject(with: pathsData) as? [String],
       !paths.isEmpty {
      urls = paths
        .filter { FileManager.default.fileExists(atPath: $0) }
        .map { URL(fileURLWithPath: $0) }
      headers = [:]
      emit("[NativeCore] ensureLoaded: \(itemId) downloaded, \(urls.count) tracks")
    } else if let urlsJson = defaults?.string(forKey: "np_stream_urls_json"),
              let urlsData = urlsJson.data(using: .utf8),
              let urlStrings = try? JSONSerialization.jsonObject(with: urlsData) as? [String],
              !urlStrings.isEmpty {
      urls = urlStrings.compactMap { URL(string: $0) }
      var hh: [String: String] = [:]
      if let headersJson = defaults?.string(forKey: "np_stream_headers_json"),
         let headersData = headersJson.data(using: .utf8),
         let h = try? JSONSerialization.jsonObject(with: headersData) as? [String: String] {
        hh = h
      }
      headers = hh
      emit("[NativeCore] ensureLoaded: \(itemId) streaming, \(urls.count) tracks, \(headers.count) custom headers")
    } else {
      emit("[NativeCore] ensureLoaded: no playable source for \(itemId)")
      return false
    }

    if urls.isEmpty {
      emit("[NativeCore] ensureLoaded: source list empty after filtering for \(itemId)")
      return false
    }

    // Track offsets (cumulative, length = urls.count + 1). The engine
    // normalizes/fills in a fallback if the stash is missing or short.
    var offsets: [Double] = [0]
    if let offsetsJson = defaults?.string(forKey: "np_track_offsets_json"),
       let offsetsData = offsetsJson.data(using: .utf8),
       let raw = try? JSONSerialization.jsonObject(with: offsetsData) as? [NSNumber],
       raw.count >= urls.count + 1 {
      offsets = raw.map { $0.doubleValue }
    } else {
      offsets = []
      emit("[NativeCore] ensureLoaded: track offsets unknown, engine will fall back")
    }

    let savedPos = defaults?.double(forKey: "np_position_s") ?? 0
    let totalS = defaults?.double(forKey: "np_total_s") ?? 0
    let speed = defaults?.double(forKey: "np_speed") ?? 1.0
    // Mirrored from the default prefs into the app group by home_widget_service
    // (eq_enabled itself isn't in the group suite).
    let eqEnabled = defaults?.bool(forKey: "np_eq_enabled") ?? false

    _currentItemId = itemId
    _currentEpisodeId = episodeId

    let tracks = urls.map { (url: $0, headers: headers) }
    AbsorbAudioEngine.shared.load(
      tracks: tracks,
      trackOffsets: offsets,
      startPositionS: savedPos,
      totalDurationS: totalS,
      speed: Float(speed > 0 ? speed : 1.0),
      volume: 1.0,
      eqEnabled: eqEnabled,
      itemId: itemId
    ) { _ in }

    configureRemoteCommandsIfNeeded()
    updateNowPlayingInfo(rate: 0)
    emit("[NativeCore] ensureLoaded done: \(itemId) global=\(savedPos)s speed=\(speed) eq=\(eqEnabled)")
    return true
  }

  /// Global position straight from the engine (already offset-aware).
  private func globalPosition() -> Double {
    return AbsorbAudioEngine.shared.globalPositionS()
  }

  private func totalDuration() -> Double {
    let defaults = UserDefaults(suiteName: Self.appGroup)
    let stashed = defaults?.double(forKey: "np_total_s") ?? 0
    return stashed > 0 ? stashed : 0
  }

  private func currentSpeed() -> Float {
    let defaults = UserDefaults(suiteName: Self.appGroup)
    let speed = defaults?.double(forKey: "np_speed") ?? 1.0
    return Float(speed > 0 ? speed : 1.0)
  }

  private func seekToGlobal(_ globalSeconds: Double) {
    AbsorbAudioEngine.shared.seekToGlobal(globalSeconds) { [weak self] _ in
      self?.queue.async {
        self?.savePosition()
        self?.updateNowPlayingInfo(rate: Double(AbsorbAudioEngine.shared.isPlaying ? (self?.currentSpeed() ?? 1.0) : 0))
        self?.syncWidgetState()
        self?.emit("[NativeCore] seekToGlobal done: \(globalSeconds)s")
      }
    }
  }

  private func activateAudioSession() {
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.playback, mode: .spokenAudio, options: [])
      try session.setActive(true)
    } catch {
      emit("[NativeCore] AVAudioSession activate failed: \(error.localizedDescription)")
    }
  }

  private func savePosition() {
    let pos = globalPosition()
    if !pos.isFinite { return }
    let defaults = UserDefaults(suiteName: Self.appGroup)
    defaults?.set(pos, forKey: "np_position_s")
    defaults?.set(AbsorbAudioEngine.shared.isPlaying, forKey: "widget_is_playing")
  }

  /// Write the engine's real play state (and progress) for the widget, then
  /// reload its timeline. Flutter does the equivalent whenever it actuates;
  /// without this the native paths only corrected the flag on pause, so a
  /// native play from a stale flag left the widget icon inverted until the
  /// next 5-minute timeline refresh.
  private func syncWidgetState() {
    let defaults = UserDefaults(suiteName: Self.appGroup)
    defaults?.set(AbsorbAudioEngine.shared.isPlaying, forKey: "widget_is_playing")
    if AbsorbAudioEngine.shared.isPlaying { absorbStampAudioActivity() }
    let total = totalDuration()
    if total > 0 {
      let permille = Int((globalPosition() / total * 1000).rounded())
      defaults?.set(min(1000, max(0, permille)), forKey: "widget_progress")
    }
    WidgetCenter.shared.reloadTimelines(ofKind: "NowPlayingWidget")
    WidgetCenter.shared.reloadTimelines(ofKind: "NowPlayingArtWidget")
  }

  // MARK: - Server sync

  private func startServerSyncTimer() {
    DispatchQueue.main.async { [weak self] in
      self?._serverSyncTimer?.invalidate()
      self?._serverSyncTimer = Timer.scheduledTimer(
        withTimeInterval: Self.serverSyncIntervalSec,
        repeats: true
      ) { _ in
        self?.queue.async { self?.pushProgressToServer() }
      }
      self?.emit("[NativeCore] server sync timer started (\(Int(Self.serverSyncIntervalSec))s)")
    }
  }

  private func stopServerSyncTimer() {
    DispatchQueue.main.async { [weak self] in
      self?._serverSyncTimer?.invalidate()
      self?._serverSyncTimer = nil
    }
  }

  /// PATCH /api/me/progress/{itemId} so other clients (and the user's own
  /// app on relaunch) see the right position. Best-effort - no retry on
  /// failure since we'll try again on the next 60s tick.
  private func pushProgressToServer() {
    // Flutter has come up and owns sync now - it reports through its own
    // playback session, while this path PATCHes bare progress. Keeping the
    // timer running past the handoff double-reported the position (and once
    // Dart replaces the stream it 404s against a session the server closed).
    if flutterIsAlive() {
      emit("[NativeCore] server sync stopped - Flutter took over")
      stopServerSyncTimer()
      return
    }
    // Runs every 60s while the native core drives playback - keeps the
    // widget's audio-activity signal fresh so it renders as playing.
    if AbsorbAudioEngine.shared.isPlaying { absorbStampAudioActivity() }
    let defaults = UserDefaults(suiteName: Self.appGroup)
    guard let itemId = _currentItemId,
          let serverUrl = defaults?.string(forKey: "np_server_url"),
          let token = defaults?.string(forKey: "np_api_token"),
          !token.isEmpty
    else {
      emit("[NativeCore] pushProgressToServer: missing itemId/server/token")
      return
    }
    let pos = globalPosition()
    let cleanBase = serverUrl.hasSuffix("/")
      ? String(serverUrl.dropLast())
      : serverUrl
    let progressKey: String
    if let ep = _currentEpisodeId, !ep.isEmpty {
      progressKey = "\(itemId)-\(ep)"
    } else {
      progressKey = itemId
    }
    guard let url = URL(string: "\(cleanBase)/api/me/progress/\(progressKey)") else {
      emit("[NativeCore] pushProgressToServer: bad URL for \(progressKey)")
      return
    }

    var req = URLRequest(url: url)
    req.httpMethod = "PATCH"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    if let headersJson = defaults?.string(forKey: "np_stream_headers_json"),
       let headersData = headersJson.data(using: .utf8),
       let headers = try? JSONSerialization.jsonObject(with: headersData) as? [String: String] {
      for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
    }
    let body: [String: Any] = ["currentTime": pos]
    req.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: req) { [weak self] _, response, error in
      let status = (response as? HTTPURLResponse)?.statusCode ?? -1
      if let error = error {
        self?.emit("[NativeCore] server sync error: \(error.localizedDescription)")
      } else {
        self?.emit("[NativeCore] server sync \(progressKey) currentTime=\(pos) status=\(status)")
      }
    }.resume()
  }

  // MARK: - MPNowPlayingInfoCenter

  private func updateNowPlayingInfo(rate: Double) {
    guard _currentItemId != nil else { return }
    let defaults = UserDefaults(suiteName: Self.appGroup)
    let title = defaults?.string(forKey: "np_title")
      ?? defaults?.string(forKey: "widget_title")
      ?? ""
    let author = defaults?.string(forKey: "np_author")
      ?? defaults?.string(forKey: "widget_author")
      ?? ""
    let coverPath = defaults?.string(forKey: "np_cover_path")
      ?? defaults?.string(forKey: "widget_cover_path")
    let duration = totalDuration()
    let elapsed = globalPosition()

    var info: [String: Any] = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: author,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
      MPNowPlayingInfoPropertyPlaybackRate: rate,
      MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
    ]
    if duration > 0 {
      info[MPMediaItemPropertyPlaybackDuration] = duration
    }
    if let coverPath = coverPath, let img = UIImage(contentsOfFile: coverPath) {
      let artwork = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
      info[MPMediaItemPropertyArtwork] = artwork
    }
    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
  }

  // MARK: - MPRemoteCommandCenter

  /// Point the lock screen skip buttons at the user's skip amounts. Called
  /// from Dart at startup and whenever the setting (or the playing item's
  /// per-library override) changes. Applies immediately even before the
  /// commands are armed, because `preferredIntervals` lives on the shared
  /// command center and whoever writes it last wins - audio_service only
  /// writes it when it re-applies its controls.
  func setSkipIntervals(forward: Int, backward: Int) {
    queue.async { [weak self] in
      guard let self = self else { return }
      let fwd = max(1, forward)
      let back = max(1, backward)
      if fwd != self._skipForwardSec || back != self._skipBackwardSec {
        self.emit("[NativeCore] skip intervals fwd=\(fwd)s back=\(back)s")
      }
      self._skipForwardSec = fwd
      self._skipBackwardSec = back
      // Always re-assert, even when unchanged: audio_service writes the same
      // properties whenever it re-applies its controls (it does after a stop),
      // so a push that looks redundant here may still be undoing a stale write.
      DispatchQueue.main.async {
        let cc = MPRemoteCommandCenter.shared()
        cc.skipForwardCommand.preferredIntervals = [NSNumber(value: fwd)]
        cc.skipBackwardCommand.preferredIntervals = [NSNumber(value: back)]
      }
    }
  }

  /// Register the remote command handlers up front, without loading a player or
  /// starting playback. They defer to Flutter while it's alive, so this is a
  /// no-op for normal foreground use - but it guarantees a native target stays
  /// registered for the play command. Without it, the handlers were only wired
  /// the first time the native core played, so a play after iOS suspended a
  /// paused Flutter found no responsive Now Playing app and iOS handed control
  /// to Apple Music. Idempotent.
  func armRemoteCommands() {
    queue.async { [weak self] in
      self?.configureRemoteCommandsIfNeeded()
    }
  }

  private func configureRemoteCommandsIfNeeded() {
    if _commandsConfigured { return }
    _commandsConfigured = true
    let cc = MPRemoteCommandCenter.shared()

    // Each handler bails when Flutter is alive so audio_service handlers
    // win on the lock screen. When native is in charge, these drive the
    // shared engine directly.
    cc.playCommand.addTarget { [weak self] _ in
      if self?.flutterIsAlive() == true {
        self?.emit("[NativeCore] remote: play - Flutter is alive, deferring")
        return .success
      }
      self?.emit("[NativeCore] remote: play")
      self?.play()
      return .success
    }
    cc.pauseCommand.addTarget { [weak self] _ in
      if self?.flutterIsAlive() == true {
        self?.emit("[NativeCore] remote: pause - Flutter is alive, deferring")
        return .success
      }
      self?.emit("[NativeCore] remote: pause")
      self?.pause()
      return .success
    }
    cc.togglePlayPauseCommand.addTarget { [weak self] _ in
      if self?.flutterIsAlive() == true {
        self?.emit("[NativeCore] remote: toggle - Flutter is alive, deferring")
        return .success
      }
      self?.emit("[NativeCore] remote: toggle")
      self?.toggle()
      return .success
    }

    cc.skipForwardCommand.preferredIntervals = [NSNumber(value: _skipForwardSec)]
    cc.skipForwardCommand.addTarget { [weak self] event in
      let fallback = self?._skipForwardSec ?? 30
      let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? Double(fallback)
      if self?.flutterIsAlive() == true {
        self?.emit("[NativeCore] remote: skipForward - Flutter is alive, deferring")
        return .success
      }
      self?.skipForward(seconds: Int(interval))
      return .success
    }
    cc.skipBackwardCommand.preferredIntervals = [NSNumber(value: _skipBackwardSec)]
    cc.skipBackwardCommand.addTarget { [weak self] event in
      let fallback = self?._skipBackwardSec ?? 10
      let interval = (event as? MPSkipIntervalCommandEvent)?.interval ?? Double(fallback)
      if self?.flutterIsAlive() == true {
        self?.emit("[NativeCore] remote: skipBackward - Flutter is alive, deferring")
        return .success
      }
      self?.skipBackward(seconds: Int(interval))
      return .success
    }

    cc.changePlaybackPositionCommand.addTarget { [weak self] event in
      guard let event = event as? MPChangePlaybackPositionCommandEvent else {
        return .commandFailed
      }
      if self?.flutterIsAlive() == true {
        self?.emit("[NativeCore] remote: scrub - Flutter is alive, deferring")
        return .success
      }
      self?.queue.async {
        guard self?.ensureLoaded() == true else { return }
        self?.seekToGlobal(event.positionTime)
      }
      return .success
    }
    emit("[NativeCore] remote command center wired")
  }

  // MARK: - Logging

  private func emit(_ line: String) {
    NSLog("%@", line)
    Self.logSink?(line)
  }
}
