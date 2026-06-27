import AVFoundation
import Foundation
import UIKit

/// Single AVPlayer that owns audio playback for the entire app lifetime.
/// All transitions (intra-book track boundaries, cross-book swaps) go through
/// `replaceCurrentItem` on the same player. The player is never destroyed,
/// so iOS keeps granting background audio output across transitions.
final class AbsorbAudioEngine: NSObject {
  static let shared = AbsorbAudioEngine()

  static var logSink: ((String) -> Void)?

  weak var delegate: AbsorbAudioEngineDelegate?

  private let queue = DispatchQueue(label: "com.barnabas.absorb.audioengine")

  private let player: AVPlayer = {
    let p = AVPlayer()
    p.automaticallyWaitsToMinimizeStalling = false
    p.allowsExternalPlayback = false
    return p
  }()

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
  private var smartSkipEnabled: Bool = false
  private var smartSkipEpoch: UInt = 0
  private var smartSkipRangesByTrack: [Int: [AbsorbSilenceRange]] = [:]
  private var smartSkipSeekInFlight: Bool = false
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

  private override init() {
    super.init()
    addPeriodicTimeObserver()
    observeAppLifecycle()
  }

  // MARK: - Public API

  func load(tracks: [(url: URL, headers: [String: String])],
            trackOffsets: [Double],
            startPositionS: Double,
            totalDurationS: Double,
            speed: Float,
            volume: Float,
            eqEnabled: Bool,
            smartSkipEnabled: Bool,
            itemId: String? = nil,
            completion: @escaping (Double?) -> Void) {
    queue.async { [weak self] in
      guard let self = self else { completion(nil); return }
      self.activateSession()

      if let itemId = itemId { self._currentItemId = itemId }
      self.trackUrls = tracks.map { $0.url }
      self.trackHeaders = tracks.first?.headers ?? [:]
      self.trackOffsets = Self.normalizeOffsets(trackOffsets, trackCount: tracks.count, totalDurationS: totalDurationS)
      self.totalDurationS = totalDurationS
      self.speed = speed
      self.volume = volume
      self.eqEnabled = eqEnabled
      self.smartSkipEnabled = smartSkipEnabled
      self.smartSkipSeekInFlight = false
      self.smartSkipRangesByTrack = [:]
      self.smartSkipEpoch &+= 1
      self.player.volume = volume

      let targetIndex = self.trackIndexFor(globalSeconds: startPositionS)
      self.trackIndex = targetIndex
      let localStart = max(0, startPositionS - self.trackOffsets[targetIndex])

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
      self.processingState = .idle
      self.emitState()
      DispatchQueue.main.async {
        self.player.pause()
        self.player.replaceCurrentItem(with: nil)
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
        let wasPlaying = self.player.rate > 0
        self.player.seek(
          to: CMTime(seconds: localTarget, preferredTimescale: 1000),
          toleranceBefore: .zero, toleranceAfter: .zero
        ) { [weak self] finished in
          self?.queue.async {
            self?.emitPositionImmediate()
            if wasPlaying { self?.player.rate = self?.speed ?? 1.0 }
            completion(finished)
          }
        }
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

  func setSmartSkipEnabled(_ enabled: Bool) {
    queue.async { [weak self] in
      guard let self = self else { return }
      self.smartSkipEnabled = enabled
      self.smartSkipSeekInFlight = false
      self.smartSkipEpoch &+= 1
      if enabled {
        self.delegate?.engineDidChangeSmartSkipAvailability(true)
        self.startSmartSkipAnalysisForCurrentTrack()
      } else {
        self.smartSkipRangesByTrack = [:]
        self.delegate?.engineDidChangeSmartSkipAvailability(true)
      }
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
        let local = item.currentTime().seconds
        self.loadTrack(atIndex: self.trackIndex,
                       localStart: local.isFinite ? max(0, local) : 0,
                       autoPlay: true) { _ in }
      } else {
        AbsorbAudioEQProcessor.shared.attachTapSync(to: item)
        self.tapAttached = true
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

  private func startSmartSkipAnalysisForCurrentTrack() {
    guard smartSkipEnabled else { return }
    guard trackUrls.indices.contains(trackIndex) else { return }

    let epoch = smartSkipEpoch
    let index = trackIndex
    let url = trackUrls[index]
    let headers = trackHeaders
    delegate?.engineDidChangeSmartSkipAvailability(true)
    emit("[SmartSkip] analyze track=\(index) url=\(url.lastPathComponent)")

    AbsorbSilenceAnalyzer.shared.analyze(
      url: url,
      headers: headers,
      epoch: epoch,
      isCurrent: { [weak self] candidate in
        guard let self = self else { return false }
        return self.queue.sync {
          self.smartSkipEnabled && self.smartSkipEpoch == candidate
        }
      },
      completion: { [weak self] epoch, result in
        guard let self = self else { return }
        self.queue.async {
          guard self.smartSkipEnabled,
                self.smartSkipEpoch == epoch,
                self.trackIndex == index else { return }
          switch result {
          case .success(let ranges):
            self.smartSkipRangesByTrack[index] = ranges
            self.delegate?.engineDidChangeSmartSkipAvailability(true)
            self.emit("[SmartSkip] analyzed track=\(index) ranges=\(ranges.count)")
          case .failure(let error):
            self.smartSkipRangesByTrack[index] = []
            self.delegate?.engineDidChangeSmartSkipAvailability(false)
            self.emit("[SmartSkip] analyze failed: \(error.localizedDescription)")
          }
        }
      }
    )
  }

  private func maybePerformSmartSkip(at localPosition: Double) {
    guard smartSkipEnabled,
          !smartSkipSeekInFlight,
          player.rate > 0,
          let ranges = smartSkipRangesByTrack[trackIndex],
          !ranges.isEmpty else { return }

    guard let range = ranges.first(where: {
      localPosition >= $0.start && localPosition < $0.end
    }) else { return }

    let target = range.end
    guard target - localPosition > 0.05 else { return }

    smartSkipSeekInFlight = true
    let speedAfterSeek = speed
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      self.player.seek(to: CMTime(seconds: target, preferredTimescale: 1000),
                       toleranceBefore: .zero,
                       toleranceAfter: .zero) { _ in
        self.queue.async {
          self.player.rate = speedAfterSeek
          self.smartSkipSeekInFlight = false
          self.delegate?.engineDidSmartSkipJump(from: localPosition, to: target)
          self.emitPositionImmediate()
        }
      }
    }
  }

  /// Track-local position; Dart adds the track offset (just_audio contract).
  func getPositionS() -> Double {
    let local = player.currentItem?.currentTime().seconds ?? 0
    return local.isFinite ? max(0, local) : 0
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
      let local = player.currentItem?.currentTime().seconds ?? 0
      let safeLocal = local.isFinite ? max(0, local) : 0
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
    processingState = .loading
    emitState()

    // Preload tracks so the EQ tap can attach synchronously before playback
    // (attachTapSync), and so load failures surface early.
    let asset = item.asset
    asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) { [weak self] in
      guard let self = self else { completion(nil); return }
      var err: NSError?
      let status = asset.statusOfValue(forKey: "tracks", error: &err)
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
        self.player.replaceCurrentItem(with: item)
        self.queue.async {
          self.smartSkipSeekInFlight = false
          self.smartSkipEpoch &+= 1
          self.smartSkipRangesByTrack[index] = []
          if self.smartSkipEnabled {
            self.startSmartSkipAnalysisForCurrentTrack()
          }
        }

        let finish: (Bool) -> Void = { _ in
          if autoPlay {
            self.player.play()
            self.player.rate = self.speed
          }
          self.queue.async {
            self.emit("[AudioEngine] loadTrack idx=\(index) localStart=\(localStart) autoPlay=\(autoPlay)")
            completion(self.totalDurationS > 0 ? self.totalDurationS : nil)
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
    ) { [weak self] _ in
      self?.queue.async { self?.handleItemEnd() }
    }

    statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
      self?.queue.async {
        switch item.status {
        case .readyToPlay:
          self?.processingState = .ready
          self?.emitState()
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

  private func handleItemEnd() {
    let nextTrack = trackIndex + 1
    if nextTrack < trackUrls.count {
      trackIndex = nextTrack
      // Player is paused now that the item ended; reading player.rate would
      // wrongly report autoPlay=false. Intra-book advance should keep playing.
      loadTrack(atIndex: nextTrack, localStart: 0, autoPlay: true) { _ in }
      delegate?.engineDidChangeTrack(trackIndex: nextTrack, totalTracks: trackUrls.count)
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
    smartSkipSeekInFlight = false
    smartSkipEpoch &+= 1
    smartSkipRangesByTrack = [:]

    observeNewCurrentItem(item)

    let startS = nextStartS
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
      self.player.replaceCurrentItem(with: item)
      self.queue.async {
        if self.smartSkipEnabled {
          self.startSmartSkipAnalysisForCurrentTrack()
        }
      }
      if startS > 0 {
        item.seek(to: CMTime(seconds: startS, preferredTimescale: 1000),
                  toleranceBefore: .zero, toleranceAfter: .zero) { _ in
          self.queue.async {
            self.player.play()
            self.player.rate = self.speed
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
    maybePerformSmartSkip(at: pos)
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
