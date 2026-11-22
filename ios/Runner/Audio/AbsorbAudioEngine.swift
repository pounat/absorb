import AVFoundation
import Foundation
import UIKit

/// Single AVQueuePlayer that owns audio playback for the entire app lifetime.
/// The next files of a multi-file book wait in its queue, so the player moves
/// straight on at the end of a file. Loads, seeks into another file and
/// cross-book swaps rebuild the queue on the same player. The player is never
/// destroyed, so iOS keeps granting background audio output across transitions.
final class AbsorbAudioEngine: NSObject {
  static let shared = AbsorbAudioEngine()

  static var logSink: ((String) -> Void)?

  weak var delegate: AbsorbAudioEngineDelegate?

  private let queue = DispatchQueue(label: "com.barnabas.absorb.audioengine")

  private let player: AVQueuePlayer = {
    let p = AVQueuePlayer()
    p.automaticallyWaitsToMinimizeStalling = false
    p.allowsExternalPlayback = false
    return p
  }()

  // Items in the player's queue, the playing one first. Opening the next file
  // only after the last one stopped left an audible gap between files.
  private static let tracksQueuedAhead = 2
  private var queuedTracks: [(item: AVPlayerItem, index: Int, tapped: Bool)] = []
  private var lastQueuedIndex = -1
  // Bumped whenever the queue is rebuilt, so a file still being prepared for
  // the old queue is dropped.
  private var aheadGeneration: UInt = 0
  private var aheadInFlight = false
  private var currentItemObservation: NSKeyValueObservation?

  // Track list of the currently-loaded book.
  private var trackUrls: [URL] = []
  private var trackHeaders: [String: String] = [:]
  private var trackOffsets: [Double] = [0]
  private var trackIndex: Int = 0
  private var totalDurationS: Double = 0
  private var currentItem: AVPlayerItem?
  private var currentEpoch: UInt = 0

  // Book id of whatever is currently loaded. Set by load() so the
  // Flutter-suspended controller (AbsorbPlayerCore) can tell whether the engine
  // already holds the book it was asked to resume - if so it just resumes the
  // live engine rather than reloading. Read off the engine queue.
  private var _currentItemId: String?

  // Pre-prepared next book waiting for the cross-book swap.
  private var nextTrackUrls: [URL] = []
  private var nextTrackHeaders: [String: String] = [:]
  private var nextTrackOffsets: [Double] = [0]
  private var nextTotalDurationS: Double = 0
  private var nextItem: AVPlayerItem?
  private var nextStartS: Double = 0
  private var nextItemId: String?

  // Configured player state.
  private var speed: Float = 1.0
  private var volume: Float = 1.0
  private var eqEnabled: Bool = false
  // Whether the current item physically has the processing tap installed.
  // Lets us avoid rebuilding the item to re-apply effects when a tap is
  // already present (it reads the live DSP params on its own).
  private var tapAttached: Bool = false
  private var processingState: EngineProcessingState = .idle

  // Observers.
  private var timeObserver: Any?
  private var itemEndObserver: NSObjectProtocol?
  private var statusObservation: NSKeyValueObservation?
  private var tcsObservation: NSKeyValueObservation?
  private var bufferedObservation: NSKeyValueObservation?
  private var playbackBufferEmptyObs: NSKeyValueObservation?

  // Position emit throttling. Set up a 5 Hz observer; sampling rate to delegate
  // is 5 Hz foreground, 1 Hz background.
  private var lastEmittedSecondInt: Int = -1
  private var isBackgrounded: Bool = false

  // Where the last seek or load asked to be, reported as the position until
  // the player is confirmed there. A dropped seek used to read back as 0 (GH #414).
  private let positionLock = NSLock()
  private var pendingSeekS: Double?
  private var lastGoodPositionS: Double = 0
  private var seekSerial: UInt = 0
  private var seekAttempts = 0
  private var lastEmitSerial: UInt = 0
  private var lastEmittedPosS: Double = 0
  private var timeUnreadable = false
  private static let seekLandedToleranceS = 2.0

  private override init() {
    super.init()
    addPeriodicTimeObserver()
    observeAppLifecycle()
    currentItemObservation = player.observe(\.currentItem, options: [.new]) { [weak self] _, _ in
      self?.queue.async { self?.handleQueueAdvance() }
    }
  }

  // MARK: - Public API

  func load(tracks: [(url: URL, headers: [String: String])],
            trackOffsets: [Double],
            startPositionS: Double,
            totalDurationS: Double,
            speed: Float,
            volume: Float,
            eqEnabled: Bool,
            itemId: String? = nil,
            startTrackIndex: Int? = nil,
            completion: @escaping (Double?) -> Void) {
    queue.async { [weak self] in
      guard let self = self else { completion(nil); return }
      // No session activation here: loading is silent, and play() activates
      // before any audio starts. Activating on load stole the audio from
      // whatever was playing (Spotify stopped the moment Absorb opened) when
      // the launch hot-load began loading the last book paused - exactly the
      // case the NowPlayingPrimer's other-audio guard exists to avoid.
      if let itemId = itemId { self._currentItemId = itemId }
      self.trackUrls = tracks.map { $0.url }
      self.trackHeaders = tracks.first?.headers ?? [:]
      self.trackOffsets = Self.normalizeOffsets(trackOffsets, trackCount: tracks.count, totalDurationS: totalDurationS)
      self.totalDurationS = totalDurationS
      self.speed = speed
      self.volume = volume
      self.eqEnabled = eqEnabled
      self.player.volume = volume

      // Flutter loads with an explicit track and a track-local start, the
      // same shape as seek(), because it hands over no offsets: deriving the
      // track from a "global" start here put every mid-book load on track 0
      // and clamped the position to that track's end. The widget core still
      // loads by global position with the offsets it stashed.
      let targetIndex: Int
      let localStart: Double
      if let explicit = startTrackIndex, explicit >= 0, explicit < tracks.count {
        targetIndex = explicit
        localStart = max(0, startPositionS)
      } else {
        targetIndex = self.trackIndexFor(globalSeconds: startPositionS)
        localStart = max(0, startPositionS - self.trackOffsets[targetIndex])
      }
      self.trackIndex = targetIndex

      self.loadTrack(atIndex: targetIndex, localStart: localStart, autoPlay: false, completion: completion)
    }
  }

  func play() {
    queue.async { [weak self] in
      guard let self = self else { return }
      self.activateSession()
      self.player.play()
      self.player.rate = self.speed
      self.emitState()
    }
  }

  func pause() {
    queue.async { [weak self] in
      guard let self = self else { return }
      self.player.pause()
      self.emitState()
    }
  }

  func stop() {
    queue.async { [weak self] in
      guard let self = self else { return }
      self.currentItem = nil
      self._currentItemId = nil
      self.resetQueuedTracks()
      self.processingState = .idle
      self.emitState()
      DispatchQueue.main.async {
        self.player.pause()
        self.player.removeAllItems()
        self.queue.async { _ = self.beginSeek(nil, fallback: 0) }
      }
    }
  }

  /// Seek to `localS` within track `trackIndex` (nil = current track).
  func seek(toLocalS localS: Double, trackIndex: Int?, completion: @escaping (Bool) -> Void) {
    queue.async { [weak self] in
      guard let self = self else { completion(false); return }
      guard !self.trackUrls.isEmpty else { completion(false); return }
      let requested = trackIndex ?? self.trackIndex
      let target = max(0, min(requested, self.trackUrls.count - 1))
      let localTarget = localS.isFinite ? max(0, localS) : 0

      if target == self.trackIndex, self.currentItem != nil {
        let serial = self.beginSeek(localTarget, fallback: localTarget)
        self.applySeek(localTarget, serial: serial, completion: completion)
      } else {
        let wasPlaying = self.player.rate > 0
        self.trackIndex = target
        self.loadTrack(atIndex: target, localStart: localTarget, autoPlay: wasPlaying) { _ in
          completion(true)
        }
        self.delegate?.engineDidChangeTrack(trackIndex: target, totalTracks: self.trackUrls.count)
      }
    }
  }

  func setSpeed(_ newSpeed: Float) {
    queue.async { [weak self] in
      guard let self = self else { return }
      self.speed = newSpeed
      if self.player.rate > 0 {
        self.player.rate = newSpeed
      }
    }
  }

  func setVolume(_ newVolume: Float) {
    queue.async { [weak self] in
      guard let self = self else { return }
      self.volume = newVolume
      self.player.volume = newVolume
    }
  }

  func setNextSource(tracks: [(url: URL, headers: [String: String])],
                     trackOffsets: [Double],
                     startPositionS: Double,
                     totalDurationS: Double,
                     itemId: String? = nil,
                     completion: @escaping (Bool) -> Void) {
    queue.async { [weak self] in
      guard let self = self else { completion(false); return }
      self.nextTrackUrls = tracks.map { $0.url }
      self.nextTrackHeaders = tracks.first?.headers ?? [:]
      self.nextTrackOffsets = Self.normalizeOffsets(trackOffsets, trackCount: tracks.count, totalDurationS: totalDurationS)
      self.nextTotalDurationS = totalDurationS
      self.nextStartS = startPositionS
      self.nextItemId = itemId

      guard let firstUrl = tracks.first?.url else {
        self.nextItem = nil
        completion(false)
        return
      }
      let item = self.makePlayerItem(url: firstUrl, headers: tracks.first?.headers ?? [:])
      let asset = item.asset
      asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) { [weak self] in
        guard let self = self else { return }
        var err: NSError?
        let status = asset.statusOfValue(forKey: "tracks", error: &err)
        if status != .loaded {
          self.emit("[AudioEngine] setNextSource: tracks not loaded status=\(status.rawValue) err=\(err?.localizedDescription ?? "nil")")
          self.queue.async {
            self.nextItem = nil
            completion(false)
          }
          return
        }
        self.queue.async {
          self.nextItem = item
          self.emit("[AudioEngine] setNextSource prepared: \(firstUrl.lastPathComponent)")
          completion(true)
        }
      }
    }
  }

  func clearNextSource() {
    queue.async { [weak self] in
      self?.nextTrackUrls = []
      self?.nextTrackHeaders = [:]
      self?.nextTrackOffsets = [0]
      self?.nextTotalDurationS = 0
      self?.nextStartS = 0
      self?.nextItem = nil
      self?.nextItemId = nil
    }
  }

  /// Ensure the processing tap is live so EQ/effects apply. A tap can't be
  /// added to an already-playing item, so if one isn't attached we rebuild the
  /// current track in place (brief reload). If a tap is already present it
  /// reads the live DSP params itself - nothing to do.
  func attachEqualizerTap() {
    queue.async { [weak self] in
      guard let self = self else { return }
      self.eqEnabled = true
      if self.tapAttached { return }
      guard let item = self.currentItem else { return }
      if self.player.rate > 0 {
        self.loadTrack(atIndex: self.trackIndex,
                       localStart: self.getPositionS(),
                       autoPlay: true) { _ in }
      } else {
        AbsorbAudioEQProcessor.shared.attachTapSync(to: item)
        self.tapAttached = true
        if !self.queuedTracks.isEmpty { self.queuedTracks[0].tapped = true }
        // Queued files were built without the tap.
        self.requeueAhead()
      }
    }
  }

  /// Stop applying effects. Lazy: the DSP params are already zeroed by the
  /// caller, so the tap (if attached) just passes through. We leave it in place
  /// to avoid a reload blip; it won't reattach on the next track load.
  func detachEqualizerTap() {
    queue.async { [weak self] in
      guard let self = self else { return }
      self.eqEnabled = false
    }
  }

  /// Track-local position; Dart adds the track offset (just_audio contract).
  func getPositionS() -> Double {
    let raw = player.currentItem?.currentTime().seconds ?? .nan
    positionLock.lock()
    defer { positionLock.unlock() }
    if let pending = pendingSeekS { return pending }
    if raw.isFinite { lastGoodPositionS = max(0, raw) }
    return lastGoodPositionS
  }

  func getBufferedPositionS() -> Double {
    guard let item = player.currentItem else { return 0 }
    guard let last = item.loadedTimeRanges.last as? NSValue else { return 0 }
    let range = last.timeRangeValue
    let bufferedLocal = CMTimeGetSeconds(range.start + range.duration)
    return bufferedLocal.isFinite ? max(0, bufferedLocal) : 0
  }

  // MARK: - Adoption helpers (for the Flutter-suspended controller)
  //
  // AbsorbPlayerCore drives this same shared engine when Flutter is suspended.
  // These let it decide whether to reload, and read/save position in the
  // global coordinate space (the engine works in track-local space internally,
  // but the app group and server store global seconds).

  /// Book id of the currently-loaded book, or nil if nothing is loaded.
  var currentItemId: String? {
    queue.sync { _currentItemId }
  }

  /// True once a source has been loaded (and not stopped).
  var isLoaded: Bool {
    queue.sync { !trackUrls.isEmpty && currentItem != nil }
  }

  /// True while the player is actively playing (rate > 0).
  var isPlaying: Bool {
    player.rate > 0 || player.timeControlStatus == .playing
  }

  /// Current track index within the loaded book.
  var currentTrackIndex: Int {
    queue.sync { trackIndex }
  }

  /// Global position = track-local position + the current track's offset.
  func globalPositionS() -> Double {
    queue.sync {
      let safeLocal = getPositionS()
      let base = trackOffsets.indices.contains(trackIndex) ? trackOffsets[trackIndex] : 0
      let baseSafe = base.isFinite ? base : 0
      return baseSafe + safeLocal
    }
  }

  /// Convert a global position to (localS, trackIndex) and seek there. Used by
  /// the controller's skip / scrub handlers, which think in global seconds.
  func seekToGlobal(_ globalSeconds: Double, completion: @escaping (Bool) -> Void) {
    queue.async { [weak self] in
      guard let self = self else { completion(false); return }
      let target = self.trackIndexFor(globalSeconds: globalSeconds)
      let base = self.trackOffsets.indices.contains(target) ? self.trackOffsets[target] : 0
      let local = max(0, globalSeconds - (base.isFinite ? base : 0))
      self.seek(toLocalS: local, trackIndex: target, completion: completion)
    }
  }

  // MARK: - Seek bookkeeping

  /// Starts a new seek generation. With a target, getPositionS reports that
  /// target until the player is confirmed there.
  private func beginSeek(_ targetS: Double?, fallback: Double) -> UInt {
    seekSerial &+= 1
    seekAttempts = 0
    positionLock.lock()
    pendingSeekS = targetS
    lastGoodPositionS = max(0, fallback)
    positionLock.unlock()
    return seekSerial
  }

  private func pendingSeekTarget() -> Double? {
    positionLock.lock()
    defer { positionLock.unlock() }
    return pendingSeekS
  }

  private func clearPendingSeek() {
    positionLock.lock()
    pendingSeekS = nil
    positionLock.unlock()
  }

  private func applySeek(_ localS: Double, serial: UInt, completion: ((Bool) -> Void)?) {
    let wasPlaying = player.rate > 0
    player.seek(
      to: CMTime(seconds: localS, preferredTimescale: 1000),
      toleranceBefore: .zero, toleranceAfter: .zero
    ) { [weak self] finished in
      guard let self = self else { completion?(finished); return }
      self.queue.async {
        if wasPlaying { self.player.rate = self.speed }
        self.settlePendingSeek(serial: serial)
        self.emitPositionImmediate()
        completion?(finished)
      }
    }
  }

  /// A seek reported back: seek again if the player is not really there.
  private func settlePendingSeek(serial: UInt) {
    guard serial == seekSerial, let target = pendingSeekTarget() else { return }
    // Not ready yet: the status observer picks it up from here.
    guard let item = player.currentItem, item.status == .readyToPlay else { return }
    let raw = item.currentTime().seconds
    let duration = item.duration.seconds
    let landed = raw.isFinite && abs(raw - target) <= Self.seekLandedToleranceS
    let pastEnd = duration.isFinite && target >= duration - 1
    if landed || pastEnd {
      clearPendingSeek()
      return
    }
    if seekAttempts >= 2 {
      emit("[AudioEngine] seek to \(target)s did not land (at \(raw)s), giving up")
      clearPendingSeek()
      return
    }
    seekAttempts += 1
    emit("[AudioEngine] seek to \(target)s did not land (at \(raw)s), trying again")
    applySeek(target, serial: serial, completion: nil)
  }

  /// AVPlayer drops a seek made before the item is ready, so check on ready.
  private func seekPendingOnReady() {
    guard let target = pendingSeekTarget() else { return }
    let raw = player.currentItem?.currentTime().seconds ?? .nan
    if raw.isFinite && abs(raw - target) <= Self.seekLandedToleranceS {
      clearPendingSeek()
      return
    }
    emit("[AudioEngine] item ready at \(raw)s, seeking to the pending \(target)s")
    applySeek(target, serial: seekSerial, completion: nil)
  }

  // MARK: - Track loading

  private func loadTrack(atIndex index: Int,
                         localStart: Double,
                         autoPlay: Bool,
                         completion: @escaping (Double?) -> Void) {
    guard index < trackUrls.count else { completion(nil); return }
    let url = trackUrls[index]
    let headers = trackHeaders
    let eqEnabled = self.eqEnabled

    let item = makePlayerItem(url: url, headers: headers)
    currentEpoch &+= 1
    let myEpoch = currentEpoch
    let startSerial = beginSeek(localStart > 0 ? localStart : nil, fallback: localStart)
    resetQueuedTracks()
    lastQueuedIndex = index
    let itemEndAction = endAction(forTrack: index)
    processingState = .loading
    emitState()

    // Preload tracks so the EQ tap can attach synchronously before playback
    // (attachTapSync), and so load failures surface early.
    let asset = item.asset
    asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) { [weak self] in
      guard let self = self else { completion(nil); return }
      var err: NSError?
      let status = asset.statusOfValue(forKey: "tracks", error: &err)
      let decodedDurationS = asset.duration.seconds
      if status != .loaded {
        self.emit("[AudioEngine] loadTrack idx=\(index) tracks-load failed status=\(status.rawValue) err=\(err?.localizedDescription ?? "nil")")
      }
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { completion(nil); return }
        guard self.currentEpoch == myEpoch else {
          self.queue.async {
            self.emit("[AudioEngine] loadTrack idx=\(index) skipped (stale epoch)")
            completion(nil)
          }
          return
        }
        // Detach the outgoing item before promoting the new one, so its EQ
        // detach can't wipe the attach below.
        self.detachCurrentItem()
        self.currentItem = item
        self.observeNewCurrentItem(item)
        if eqEnabled {
          // audioMix must be set before playback starts or the tap is ignored.
          AbsorbAudioEQProcessor.shared.attachTapSync(to: item)
          self.tapAttached = true
        } else {
          self.tapAttached = false
        }
        self.player.actionAtItemEnd = itemEndAction
        self.player.removeAllItems()
        self.player.insert(item, after: nil)

        let finish: (Bool) -> Void = { _ in
          if autoPlay {
            self.player.play()
            self.player.rate = self.speed
          }
          self.queue.async {
            self.settlePendingSeek(serial: startSerial)
            self.emit("[AudioEngine] loadTrack idx=\(index) localStart=\(localStart) autoPlay=\(autoPlay)")
            if self.currentEpoch == myEpoch {
              self.queuedTracks = [(item: item, index: index, tapped: eqEnabled)]
              self.enqueueAhead()
            }
            completion(decodedDurationS.isFinite && decodedDurationS > 0 ? decodedDurationS : nil)
          }
        }

        if localStart > 0 {
          item.seek(to: CMTime(seconds: localStart, preferredTimescale: 1000),
                    toleranceBefore: .zero, toleranceAfter: .zero, completionHandler: finish)
        } else {
          finish(true)
        }
      }
    }
  }

  private func makePlayerItem(url: URL, headers: [String: String]) -> AVPlayerItem {
    var options: [String: Any] = [:]
    if !headers.isEmpty {
      options["AVURLAssetHTTPHeaderFieldsKey"] = headers
    }
    let asset = AVURLAsset(url: url, options: options)
    let item = AVPlayerItem(asset: asset)
    item.audioTimePitchAlgorithm = .timeDomain
    return item
  }

  private func detachCurrentItem() {
    if let item = currentItem, eqEnabled {
      AbsorbAudioEQProcessor.shared.detach(from: item)
    }
    if let prev = itemEndObserver {
      NotificationCenter.default.removeObserver(prev)
      itemEndObserver = nil
    }
    statusObservation?.invalidate()
    statusObservation = nil
    tcsObservation?.invalidate()
    tcsObservation = nil
    bufferedObservation?.invalidate()
    bufferedObservation = nil
    playbackBufferEmptyObs?.invalidate()
    playbackBufferEmptyObs = nil
  }

  private func observeNewCurrentItem(_ item: AVPlayerItem) {
    itemEndObserver = NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: item,
      queue: nil
    ) { [weak self, weak item] _ in
      self?.queue.async { self?.handleItemEnd(item) }
    }

    // Initial too: a queued file is usually ready before it starts playing,
    // and its duration and ready state still have to be reported.
    statusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
      self?.queue.async {
        switch item.status {
        case .readyToPlay:
          self?.processingState = .ready
          self?.emitState()
          self?.seekPendingOnReady()
          let d = item.asset.duration.seconds
          if d.isFinite { self?.delegate?.engineDidLoadDuration(d) }
        case .failed:
          self?.processingState = .idle
          self?.emit("[AudioEngine] item failed: \(item.error?.localizedDescription ?? "unknown")")
          self?.delegate?.engineDidError(message: item.error?.localizedDescription ?? "item failed", code: nil)
        default:
          break
        }
      }
    }

    tcsObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] _, _ in
      self?.queue.async {
        guard let self = self else { return }
        switch self.player.timeControlStatus {
        case .paused:
          if self.processingState == .buffering { self.processingState = .ready }
        case .waitingToPlayAtSpecifiedRate:
          self.processingState = .buffering
        case .playing:
          self.processingState = .ready
        @unknown default:
          break
        }
        self.emitState()
      }
    }

    playbackBufferEmptyObs = item.observe(\.isPlaybackBufferEmpty, options: [.new]) { [weak self] item, _ in
      self?.queue.async {
        if item.isPlaybackBufferEmpty {
          self?.processingState = .buffering
          self?.emitState()
        }
      }
    }
  }

  private func handleItemEnd(_ endedItem: AVPlayerItem?) {
    // The queue already moved on to the next file.
    guard let endedItem = endedItem, endedItem === currentItem else { return }
    let nextTrack = trackIndex + 1
    if nextTrack < trackUrls.count {
      if queuedTracks.contains(where: { $0.index == nextTrack }) {
        // The queue moves on by itself. If it hasn't shortly (the file was
        // still being added when this one ended), load it the old way.
        queue.asyncAfter(deadline: .now() + 1) { [weak self] in
          guard let self = self, self.currentItem === endedItem else { return }
          self.emit("[AudioEngine] queue did not move on to idx=\(nextTrack), loading it")
          self.loadNextTrackAfterEnd(nextTrack)
        }
        return
      }
      loadNextTrackAfterEnd(nextTrack)
      return
    }

    if nextItem != nil {
      swapToNextBook()
      return
    }

    processingState = .completed
    emitState()
    delegate?.engineDidCompleteBook()
  }

  private func loadNextTrackAfterEnd(_ nextTrack: Int) {
    trackIndex = nextTrack
    // Player is paused now that the item ended; reading player.rate would
    // wrongly report autoPlay=false. Intra-book advance should keep playing.
    loadTrack(atIndex: nextTrack, localStart: 0, autoPlay: true) { _ in }
    delegate?.engineDidChangeTrack(trackIndex: nextTrack, totalTracks: trackUrls.count)
  }

  // MARK: - Track queue

  /// The player moved on to a queued file at the end of the last one.
  private func handleQueueAdvance() {
    guard let item = player.currentItem, item !== currentItem,
          let position = queuedTracks.firstIndex(where: { $0.item === item }) else { return }
    let entry = queuedTracks[position]
    if position > 1 {
      emit("[AudioEngine] queue skipped \(position - 1) file(s) before idx=\(entry.index)")
    }
    queuedTracks.removeFirst(position)
    detachCurrentItem()
    currentItem = item
    trackIndex = entry.index
    tapAttached = entry.tapped
    _ = beginSeek(nil, fallback: 0)
    observeNewCurrentItem(item)
    let itemEndAction = endAction(forTrack: entry.index)
    DispatchQueue.main.async { self.player.actionAtItemEnd = itemEndAction }
    emit("[AudioEngine] queue moved on to idx=\(entry.index)")
    delegate?.engineDidChangeTrack(trackIndex: entry.index, totalTracks: trackUrls.count)
    enqueueAhead()
  }

  /// Advance through the book's files, but stop on the last one so the end of
  /// the book still leaves it loaded (completion, next-book swap, replay).
  private func endAction(forTrack index: Int) -> AVPlayer.ActionAtItemEnd {
    index + 1 < trackUrls.count ? .advance : .pause
  }

  private func resetQueuedTracks() {
    queuedTracks = []
    aheadGeneration &+= 1
    aheadInFlight = false
  }

  /// Prepare the next file and add it behind the queued ones, one at a time so
  /// they stay in order, until enough are waiting.
  private func enqueueAhead() {
    guard !aheadInFlight, let playing = queuedTracks.first, playing.item === currentItem else { return }
    let index = lastQueuedIndex + 1
    guard index < trackUrls.count, index <= playing.index + Self.tracksQueuedAhead else { return }
    aheadInFlight = true
    let generation = aheadGeneration
    let tap = eqEnabled
    let item = makePlayerItem(url: trackUrls[index], headers: trackHeaders)
    let asset = item.asset
    asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) { [weak self] in
      guard let self = self else { return }
      var err: NSError?
      let loaded = asset.statusOfValue(forKey: "tracks", error: &err) == .loaded
      self.queue.async {
        guard generation == self.aheadGeneration else { return }
        guard loaded, let after = self.queuedTracks.last?.item else {
          self.aheadInFlight = false
          self.emit("[AudioEngine] could not queue idx=\(index) err=\(err?.localizedDescription ?? "nil")")
          return
        }
        // Listed before it is inserted, so an advance onto it is recognised.
        self.queuedTracks.append((item: item, index: index, tapped: tap))
        self.lastQueuedIndex = index
        DispatchQueue.main.async {
          // The file it goes after may have finished already.
          let inserted = self.player.items().contains { $0 === after }
            && self.player.canInsert(item, after: after)
          if inserted {
            // audioMix must be set before playback starts or the tap is ignored.
            if tap { AbsorbAudioEQProcessor.shared.attachTapSync(to: item) }
            self.player.insert(item, after: after)
          }
          self.queue.async {
            guard generation == self.aheadGeneration else { return }
            self.aheadInFlight = false
            if inserted {
              self.enqueueAhead()
            } else {
              self.queuedTracks.removeAll { $0.item === item }
              self.lastQueuedIndex = index - 1
            }
          }
        }
      }
    }
  }

  /// Rebuild the files queued behind the playing one.
  private func requeueAhead() {
    guard let playing = queuedTracks.first else { return }
    let stale = queuedTracks.dropFirst().map { $0.item }
    resetQueuedTracks()
    queuedTracks = [playing]
    lastQueuedIndex = playing.index
    DispatchQueue.main.async {
      for item in stale { self.player.remove(item) }
      self.queue.async { self.enqueueAhead() }
    }
  }

  private func swapToNextBook() {
    guard let item = nextItem else { return }

    detachCurrentItem()

    trackUrls = nextTrackUrls
    trackHeaders = nextTrackHeaders
    trackOffsets = nextTrackOffsets
    totalDurationS = nextTotalDurationS
    trackIndex = 0
    // Promote the next book's id so the widget controller recognises the book
    // the engine is now actually playing (otherwise a widget tap after an
    // auto-advance would reload and restart the new book's stream).
    if let nextId = nextItemId { _currentItemId = nextId }

    currentItem = item
    currentEpoch &+= 1
    resetQueuedTracks()
    queuedTracks = [(item: item, index: 0, tapped: eqEnabled)]
    lastQueuedIndex = 0
    let itemEndAction = endAction(forTrack: 0)

    observeNewCurrentItem(item)

    let startS = nextStartS
    let startSerial = beginSeek(startS > 0 ? startS : nil, fallback: startS)
    // Inline clear so the next swap can be armed before our async block runs.
    nextTrackUrls = []
    nextTrackHeaders = [:]
    nextTrackOffsets = [0]
    nextTotalDurationS = 0
    nextStartS = 0
    nextItem = nil
    nextItemId = nil

    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if self.eqEnabled {
        // audioMix must be set before playback starts or the tap is ignored.
        AbsorbAudioEQProcessor.shared.attachTapSync(to: item)
        self.tapAttached = true
      } else {
        self.tapAttached = false
      }
      self.player.actionAtItemEnd = itemEndAction
      self.player.removeAllItems()
      self.player.insert(item, after: nil)
      self.queue.async { self.enqueueAhead() }
      if startS > 0 {
        item.seek(to: CMTime(seconds: startS, preferredTimescale: 1000),
                  toleranceBefore: .zero, toleranceAfter: .zero) { _ in
          self.queue.async {
            self.player.play()
            self.player.rate = self.speed
            self.settlePendingSeek(serial: startSerial)
            self.emit("[AudioEngine] swapToNextBook done at startS=\(startS) rate=\(self.player.rate)")
            self.delegate?.engineDidAutoAdvance()
            self.delegate?.engineDidLoadDuration(self.totalDurationS > 0 ? self.totalDurationS : nil)
          }
        }
      } else {
        self.player.play()
        self.player.rate = self.speed
        self.queue.async {
          self.emit("[AudioEngine] swapToNextBook done at startS=0 rate=\(self.player.rate)")
          self.delegate?.engineDidAutoAdvance()
          self.delegate?.engineDidLoadDuration(self.totalDurationS > 0 ? self.totalDurationS : nil)
        }
      }
    }
  }

  // MARK: - Audio session

  private func activateSession() {
    let session = AVAudioSession.sharedInstance()
    do {
      if session.category != .playback {
        try session.setCategory(.playback, mode: .spokenAudio, policy: .longFormAudio)
      }
      try session.setActive(true)
    } catch {
      emit("[AudioEngine] session activate failed: \(error.localizedDescription)")
    }
  }

  // MARK: - Position emit + lifecycle

  private func addPeriodicTimeObserver() {
    let interval = CMTime(seconds: 0.2, preferredTimescale: 1000)
    timeObserver = player.addPeriodicTimeObserver(
      forInterval: interval, queue: .main
    ) { [weak self] _ in
      self?.queue.async { self?.maybeEmitPosition() }
    }
  }

  private func maybeEmitPosition() {
    let pos = getPositionS()
    guard pos.isFinite else { return }
    let raw = player.currentItem?.currentTime().seconds ?? .nan
    if raw.isFinite {
      timeUnreadable = false
    } else if !timeUnreadable, pendingSeekTarget() == nil {
      timeUnreadable = true
      emit("[AudioEngine] player time unreadable, holding \(pos)s")
    }
    if seekSerial == lastEmitSerial, pos < lastEmittedPosS - 30 {
      emit("[AudioEngine] position fell \(lastEmittedPosS)s -> \(pos)s with no seek")
    }
    lastEmitSerial = seekSerial
    lastEmittedPosS = pos
    let posInt = Int(pos)
    let stride = isBackgrounded ? 1 : 0
    if isBackgrounded {
      if posInt == lastEmittedSecondInt { return }
      lastEmittedSecondInt = posInt
    } else {
      // Foreground: emit every observer tick (~5 Hz).
      _ = stride
    }
    delegate?.engineDidEmitPosition(pos)
  }

  private func emitPositionImmediate() {
    let pos = getPositionS()
    guard pos.isFinite else { return }
    lastEmittedSecondInt = Int(pos)
    delegate?.engineDidEmitPosition(pos)
  }

  private func emitState() {
    let snap = EngineStateSnapshot(
      playing: player.rate > 0 || player.timeControlStatus == .playing,
      processingState: processingState,
      timeControlStatus: player.timeControlStatus.rawValue,
      reasonForWaitingToPlay: player.reasonForWaitingToPlay?.rawValue
    )
    delegate?.engineDidChangeState(snap)
  }

  private func observeAppLifecycle() {
    NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification,
      object: nil, queue: .main
    ) { [weak self] _ in self?.queue.async { self?.isBackgrounded = true } }
    NotificationCenter.default.addObserver(
      forName: UIApplication.willEnterForegroundNotification,
      object: nil, queue: .main
    ) { [weak self] _ in self?.queue.async { self?.isBackgrounded = false } }
  }

  // MARK: - Helpers

  private func trackIndexFor(globalSeconds: Double) -> Int {
    if globalSeconds <= 0 { return 0 }
    let trackCount = max(1, trackOffsets.count - 1)
    for i in 0..<trackCount {
      let nextOffset = i + 1 < trackOffsets.count ? trackOffsets[i + 1] : .greatestFiniteMagnitude
      if globalSeconds < nextOffset { return i }
    }
    return trackCount - 1
  }

  private static func normalizeOffsets(_ offsets: [Double],
                                       trackCount: Int,
                                       totalDurationS: Double) -> [Double] {
    // Expect length = trackCount + 1, cumulative starting at 0. Fall back to
    // single-track if the caller passed nothing usable.
    if offsets.count == trackCount + 1, offsets.first == 0 {
      return offsets
    }
    if trackCount <= 1 || totalDurationS <= 0 {
      return [0, totalDurationS > 0 ? totalDurationS : .greatestFiniteMagnitude]
    }
    var out: [Double] = [0]
    let perTrack = totalDurationS / Double(trackCount)
    for i in 1...trackCount { out.append(perTrack * Double(i)) }
    return out
  }

  private func emit(_ line: String) {
    NSLog("%@", line)
    Self.logSink?(line)
  }
}
