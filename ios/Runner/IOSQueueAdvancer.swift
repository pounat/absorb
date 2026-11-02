import AVFoundation
import Flutter
import Foundation
import MediaPlayer
import UIKit

/// Drives the cross-book audio transition in queue mode. Builds a fresh
/// AVPlayerItem for the next book and swaps it into the AVQueuePlayer that
/// just_audio owns via replaceCurrentItem + explicit play + rate. The item
/// is foreign to just_audio, so the Dart side re-syncs just_audio on the
/// next foreground enter. MPNowPlayingInfoCenter is updated from Swift in
/// the same step so the lock screen stays alive through the swap.
final class IOSQueueAdvancer: NSObject {
  static let shared = IOSQueueAdvancer()

  static var logSink: ((String) -> Void)?

  private let queue = DispatchQueue(label: "com.barnabas.absorb.queueadvancer")

  private weak var _justAudioPlayer: AVQueuePlayer?
  private var _justAudioPlayerId: String?

  private var _preparedItem: AVPlayerItem?
  private var _preparedTitle: String = ""
  private var _preparedArtist: String = ""
  private var _preparedAlbum: String = ""
  private var _preparedDurationS: Double = 0
  private var _preparedCoverPath: String?
  private var _preparedStartS: Double = 0

  private override init() {
    super.init()
    NotificationCenter.default.addObserver(
      forName: Notification.Name("AbsorbJustAudioPlayerReady"),
      object: nil,
      queue: .main
    ) { [weak self] note in
      guard let player = note.userInfo?["player"] as? AVQueuePlayer else { return }
      let playerId = note.userInfo?["playerId"] as? String
      self?.queue.async {
        self?._justAudioPlayer = player
        self?._justAudioPlayerId = playerId
        self?.emit("[QueueAdvancer] captured just_audio player id=\(playerId ?? "?")")
      }
    }
    NotificationCenter.default.addObserver(
      forName: Notification.Name("AbsorbJustAudioPlayerReleased"),
      object: nil,
      queue: .main
    ) { [weak self] note in
      let playerId = note.userInfo?["playerId"] as? String
      self?.queue.async {
        if self?._justAudioPlayerId == playerId {
          self?._justAudioPlayer = nil
          self?._justAudioPlayerId = nil
          self?.emit("[QueueAdvancer] released just_audio player id=\(playerId ?? "?")")
        }
      }
    }
  }

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.absorb.queue_advancer",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    emit("[QueueAdvancer] channel registered")
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "prepareNext":
      let url = (args?["url"] as? String) ?? ""
      let isLocal = (args?["isLocal"] as? Bool) ?? false
      let headers = (args?["headers"] as? [String: String]) ?? [:]
      let title = (args?["title"] as? String) ?? ""
      let artist = (args?["artist"] as? String) ?? ""
      let album = (args?["album"] as? String) ?? ""
      let duration = (args?["durationS"] as? Double) ?? 0
      let coverPath = args?["coverPath"] as? String
      let startS = (args?["startS"] as? Double) ?? 0
      prepareNext(
        urlStr: url,
        isLocal: isLocal,
        headers: headers,
        title: title,
        artist: artist,
        album: album,
        durationS: duration,
        coverPath: coverPath,
        startS: startS,
        completion: { ok in result(ok) }
      )

    case "commitAdvance":
      let speed = (args?["speed"] as? Double) ?? 1.0
      commitAdvance(speed: speed, completion: { ok in result(ok) })

    case "getPositionS":
      queue.async { [weak self] in
        let pos = self?._justAudioPlayer?.currentItem?.currentTime().seconds ?? 0
        result(pos.isFinite ? pos : 0.0)
      }

    case "clear":
      queue.async { [weak self] in self?.dropPrepared() }
      result(true)

    case "isReady":
      result(_justAudioPlayer != nil)

    case "isPrepared":
      result(_preparedItem != nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func prepareNext(
    urlStr: String,
    isLocal: Bool,
    headers: [String: String],
    title: String,
    artist: String,
    album: String,
    durationS: Double,
    coverPath: String?,
    startS: Double,
    completion: @escaping (Bool) -> Void
  ) {
    queue.async { [weak self] in
      guard let self = self else { completion(false); return }
      guard !urlStr.isEmpty else {
        self.emit("[QueueAdvancer] prepareNext: empty url")
        completion(false)
        return
      }
      let url: URL?
      if isLocal {
        let path = urlStr.hasPrefix("file://") ? String(urlStr.dropFirst(7)) : urlStr
        url = URL(fileURLWithPath: path)
      } else {
        url = URL(string: urlStr)
      }
      guard let assetUrl = url else {
        self.emit("[QueueAdvancer] prepareNext: bad url \(urlStr)")
        completion(false)
        return
      }

      var options: [String: Any] = [:]
      if !headers.isEmpty {
        options["AVURLAssetHTTPHeaderFieldsKey"] = headers
      }
      let asset = AVURLAsset(url: assetUrl, options: options)
      asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) { [weak self] in
        guard let self = self else { return }
        self.queue.async {
          var trackErr: NSError?
          let status = asset.statusOfValue(forKey: "tracks", error: &trackErr)
          if status != .loaded {
            self.emit("[QueueAdvancer] prepareNext: tracks not loaded status=\(status.rawValue) err=\(trackErr?.localizedDescription ?? "nil")")
            completion(false)
            return
          }
          let item = AVPlayerItem(asset: asset)
          item.audioTimePitchAlgorithm = .timeDomain
          self._preparedItem = item
          self._preparedTitle = title
          self._preparedArtist = artist
          self._preparedAlbum = album
          self._preparedDurationS = durationS
          self._preparedCoverPath = coverPath
          self._preparedStartS = startS
          self.emit("[QueueAdvancer] prepared \(title) (\(assetUrl.lastPathComponent)) start=\(startS)")
          completion(true)
        }
      }
    }
  }

  private func commitAdvance(speed: Double, completion: @escaping (Bool) -> Void) {
    queue.async { [weak self] in
      guard let self = self else { completion(false); return }
      guard let player = self._justAudioPlayer else {
        self.emit("[QueueAdvancer] commitAdvance: no just_audio player ref")
        completion(false)
        return
      }
      guard let item = self._preparedItem else {
        self.emit("[QueueAdvancer] commitAdvance: nothing prepared")
        completion(false)
        return
      }

      self.activateSession()
      self.publishNowPlaying(rate: speed)

      let target = Float(speed > 0 ? speed : 1.0)
      let startS = self._preparedStartS
      DispatchQueue.main.async {
        // Drop stale queued items so AVQueuePlayer can't race us into one.
        for queued in player.items() where queued !== item {
          player.remove(queued)
        }
        player.replaceCurrentItem(with: item)
        if startS > 0 {
          item.seek(to: CMTime(seconds: startS, preferredTimescale: 1000), completionHandler: { _ in
            player.play()
            player.rate = target
          })
        } else {
          player.play()
          player.rate = target
        }
        self.queue.async {
          self.emit("[QueueAdvancer] commitAdvance done rate=\(player.rate) item=\(self._preparedTitle)")
          self._preparedItem = nil
          self.publishNowPlaying(rate: Double(target))
          completion(true)
        }
      }
    }
  }

  private func dropPrepared() {
    _preparedItem = nil
    _preparedTitle = ""
    _preparedArtist = ""
    _preparedAlbum = ""
    _preparedDurationS = 0
    _preparedCoverPath = nil
    _preparedStartS = 0
  }

  private func activateSession() {
    let session = AVAudioSession.sharedInstance()
    do {
      if session.category != .playback {
        try session.setCategory(.playback, mode: .spokenAudio, policy: .longFormAudio)
      }
      try session.setActive(true)
    } catch {
      emit("[QueueAdvancer] session activate failed: \(error.localizedDescription)")
    }
  }

  private func publishNowPlaying(rate: Double) {
    let title = _preparedTitle
    let artist = _preparedArtist
    let album = _preparedAlbum
    let duration = _preparedDurationS
    let coverPath = _preparedCoverPath
    let elapsed = _preparedStartS
    guard !title.isEmpty else { return }
    var info: [String: Any] = [
      MPMediaItemPropertyTitle: title,
      MPMediaItemPropertyArtist: artist,
      MPNowPlayingInfoPropertyPlaybackRate: rate,
      MPNowPlayingInfoPropertyElapsedPlaybackTime: elapsed,
      MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
    ]
    if duration > 0 {
      info[MPMediaItemPropertyPlaybackDuration] = duration
    }
    if !album.isEmpty {
      info[MPMediaItemPropertyAlbumTitle] = album
    }
    if let coverPath = coverPath, let img = UIImage(contentsOfFile: coverPath) {
      let artwork = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
      info[MPMediaItemPropertyArtwork] = artwork
    }
    DispatchQueue.main.async {
      MPNowPlayingInfoCenter.default().nowPlayingInfo = info
      MPNowPlayingInfoCenter.default().playbackState = rate > 0 ? .playing : .paused
    }
  }

  private func emit(_ line: String) {
    NSLog("%@", line)
    Self.logSink?(line)
  }
}
