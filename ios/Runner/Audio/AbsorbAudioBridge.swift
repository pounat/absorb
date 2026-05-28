import Flutter
import Foundation

/// Wires AbsorbAudioEngine to Dart over a method channel + event channel.
final class AbsorbAudioBridge: NSObject {
  static let shared = AbsorbAudioBridge()

  static var logSink: ((String) -> Void)?

  private weak var methodChannel: FlutterMethodChannel?
  private weak var eventChannel: FlutterEventChannel?
  private var eventSink: FlutterEventSink?

  private let streamHandler = StreamHandler()

  private override init() {
    super.init()
    AbsorbAudioEngine.shared.delegate = self
    streamHandler.onSinkUpdate = { [weak self] sink in
      self?.eventSink = sink
    }
  }

  func register(with messenger: FlutterBinaryMessenger) {
    let method = FlutterMethodChannel(
      name: "com.absorb.audio_engine",
      binaryMessenger: messenger
    )
    method.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    methodChannel = method

    let events = FlutterEventChannel(
      name: "com.absorb.audio_engine.events",
      binaryMessenger: messenger
    )
    events.setStreamHandler(streamHandler)
    eventChannel = events

    emit("[AudioBridge] registered")
  }

  // MARK: - Method dispatch

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "load":
      let trackList = parseTracks(args?["tracks"])
      let offsets = (args?["trackOffsets"] as? [NSNumber])?.map { $0.doubleValue } ?? []
      let start = (args?["startPositionS"] as? Double) ?? 0
      let dur = (args?["totalDurationS"] as? Double) ?? 0
      let speed = (args?["speed"] as? Double).map { Float($0) } ?? 1.0
      let volume = (args?["volume"] as? Double).map { Float($0) } ?? 1.0
      let eq = (args?["eqEnabled"] as? Bool) ?? false
      AbsorbAudioEngine.shared.load(
        tracks: trackList,
        trackOffsets: offsets,
        startPositionS: start,
        totalDurationS: dur,
        speed: speed,
        volume: volume,
        eqEnabled: eq
      ) { duration in
        result(["durationS": duration as Any])
      }

    case "play":
      AbsorbAudioEngine.shared.play()
      result(true)

    case "pause":
      AbsorbAudioEngine.shared.pause()
      result(true)

    case "stop":
      AbsorbAudioEngine.shared.stop()
      result(true)

    case "seek":
      let pos = (args?["positionS"] as? Double) ?? 0
      let index = args?["index"] as? Int
      AbsorbAudioEngine.shared.seek(toLocalS: pos, trackIndex: index) { ok in
        result(ok)
      }

    case "setSpeed":
      let s = (args?["speed"] as? Double).map { Float($0) } ?? 1.0
      AbsorbAudioEngine.shared.setSpeed(s)
      result(true)

    case "setVolume":
      let v = (args?["volume"] as? Double).map { Float($0) } ?? 1.0
      AbsorbAudioEngine.shared.setVolume(v)
      result(true)

    case "setNextSource":
      if let tracksArg = args?["tracks"] {
        let trackList = parseTracks(tracksArg)
        let offsets = (args?["trackOffsets"] as? [NSNumber])?.map { $0.doubleValue } ?? []
        let start = (args?["startPositionS"] as? Double) ?? 0
        let dur = (args?["totalDurationS"] as? Double) ?? 0
        AbsorbAudioEngine.shared.setNextSource(
          tracks: trackList,
          trackOffsets: offsets,
          startPositionS: start,
          totalDurationS: dur
        ) { ok in result(ok) }
      } else {
        AbsorbAudioEngine.shared.clearNextSource()
        result(true)
      }

    case "clearNextSource":
      AbsorbAudioEngine.shared.clearNextSource()
      result(true)

    case "attachEqualizerTap":
      AbsorbAudioEngine.shared.attachEqualizerTap()
      result(true)

    case "detachEqualizerTap":
      AbsorbAudioEngine.shared.detachEqualizerTap()
      result(true)

    case "getPositionS":
      result(AbsorbAudioEngine.shared.getPositionS())

    case "getBufferedPositionS":
      result(AbsorbAudioEngine.shared.getBufferedPositionS())

    case "dispose":
      AbsorbAudioEngine.shared.stop()
      result(true)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func parseTracks(_ raw: Any?) -> [(url: URL, headers: [String: String])] {
    guard let list = raw as? [[String: Any]] else { return [] }
    var out: [(URL, [String: String])] = []
    for entry in list {
      guard let urlStr = entry["url"] as? String, !urlStr.isEmpty else { continue }
      let isLocal = (entry["isLocal"] as? Bool) ?? false
      let headers = (entry["headers"] as? [String: String]) ?? [:]
      let url: URL?
      if isLocal {
        let path = urlStr.hasPrefix("file://") ? String(urlStr.dropFirst(7)) : urlStr
        url = URL(fileURLWithPath: path)
      } else {
        url = URL(string: urlStr)
      }
      if let u = url { out.append((u, headers)) }
    }
    return out
  }

  private func sendEvent(_ payload: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      self?.eventSink?(payload)
    }
  }

  private func emit(_ line: String) {
    NSLog("%@", line)
    Self.logSink?(line)
  }
}

// MARK: - Engine delegate

extension AbsorbAudioBridge: AbsorbAudioEngineDelegate {
  func engineDidEmitPosition(_ positionS: Double) {
    sendEvent(["type": "position", "positionS": positionS])
  }

  func engineDidChangeState(_ state: EngineStateSnapshot) {
    sendEvent([
      "type": "state",
      "playing": state.playing,
      "processingState": state.processingState.rawValue,
      "timeControlStatus": state.timeControlStatus,
      "reasonForWaitingToPlay": state.reasonForWaitingToPlay as Any,
    ])
  }

  func engineDidLoadDuration(_ durationS: Double?) {
    sendEvent(["type": "duration", "durationS": durationS as Any])
  }

  func engineDidChangeTrack(trackIndex: Int, totalTracks: Int) {
    sendEvent([
      "type": "trackChanged",
      "trackIndex": trackIndex,
      "totalTracks": totalTracks,
    ])
  }

  func engineDidCompleteBook() {
    sendEvent(["type": "bookCompleted"])
  }

  func engineDidAutoAdvance() {
    sendEvent(["type": "bookAutoAdvanced"])
  }

  func engineDidEmitBufferedPosition(_ bufferedPositionS: Double) {
    sendEvent(["type": "bufferedPosition", "bufferedPositionS": bufferedPositionS])
  }

  func engineDidError(message: String, code: String?) {
    sendEvent(["type": "error", "message": message, "code": code as Any])
  }
}

// MARK: - Stream handler

private final class StreamHandler: NSObject, FlutterStreamHandler {
  var onSinkUpdate: ((FlutterEventSink?) -> Void)?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    onSinkUpdate?(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    onSinkUpdate?(nil)
    return nil
  }
}
