import AbsorbPlayerCore
import Flutter
import Foundation
import Intents
import UIKit

/// Talks to Dart's SiriService over `com.absorb.siri`. A Siri request can
/// launch the app in the background, where Dart is still booting, so calls
/// made before Dart says it is ready wait for it, up to their timeout.
final class SiriBridge {
  static let shared = SiriBridge()

  static var logSink: ((String) -> Void)?

  private var channel: FlutterMethodChannel?
  private(set) var dartReady = false
  private var waiting: [() -> Void] = []

  func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "com.absorb.siri", binaryMessenger: messenger)
    self.channel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  func log(_ line: String) {
    SiriBridge.logSink?("[Siri] \(line)")
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "ready":
      dartReady = true
      let pending = waiting
      waiting = []
      log("Dart is ready, \(pending.count) request(s) were waiting")
      pending.forEach { $0() }
      result(true)
    case "catalogUpdated":
      SiriLibrary.update(args)
      result(true)
    case "donate":
      SiriLibrary.donate(args)
      result(true)
    case "authorizationStatus":
      result(SiriLibrary.statusName(INPreferences.siriAuthorizationStatus()))
    case "requestAuthorization":
      INPreferences.requestSiriAuthorization { status in
        DispatchQueue.main.async {
          self.log("authorization -> \(SiriLibrary.statusName(status))")
          result(SiriLibrary.statusName(status))
        }
      }
    case "openSettings":
      if let url = URL(string: UIApplication.openSettingsURLString) {
        UIApplication.shared.open(url)
      }
      result(true)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Calls Dart, waiting for it to come up first if needed. `completion` runs
  /// once on the main queue with Dart's reply, or nil on a timeout or error;
  /// `sent` says whether the call reached Dart before that, so a slow play
  /// that is already under way isn't reported as a failure.
  func call(
    _ method: String,
    _ args: [String: Any],
    timeout: TimeInterval,
    completion: @escaping (_ reply: [String: Any]?, _ sent: Bool) -> Void
  ) {
    DispatchQueue.main.async {
      var done = false
      var sent = false
      let finish: ([String: Any]?) -> Void = { reply in
        if done { return }
        done = true
        completion(reply, sent)
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
        if !done {
          self.log("\(method) timed out after \(Int(timeout))s (dartReady=\(self.dartReady) sent=\(sent))")
        }
        finish(nil)
      }
      let send: () -> Void = {
        if done { return }
        guard let channel = self.channel else {
          finish(nil)
          return
        }
        sent = true
        channel.invokeMethod(method, arguments: args) { reply in
          finish(reply as? [String: Any])
        }
      }
      if self.dartReady {
        send()
      } else {
        self.log("\(method) waiting for Dart")
        self.waiting.append(send)
      }
    }
  }
}

/// What Siri knows about the library: the titles and names it should expect,
/// the books to suggest, and what was played (so Siri learns the listener's
/// books and offers them on the lock screen and in Spotlight).
enum SiriLibrary {
  static let catalogFileName = "siri_catalog.json"

  static func statusName(_ status: INSiriAuthorizationStatus) -> String {
    switch status {
    case .authorized: return "authorized"
    case .denied: return "denied"
    case .restricted: return "restricted"
    case .notDetermined: return "notDetermined"
    @unknown default: return "notDetermined"
    }
  }

  static func update(_ args: [String: Any]) {
    let titles = args["titles"] as? [String] ?? []
    let authors = args["authors"] as? [String] ?? []
    let shows = args["shows"] as? [String] ?? []
    let count = args["count"] as? Int ?? 0

    let context = INMediaUserContext()
    context.numberOfLibraryItems = count
    context.becomeCurrent()

    if INPreferences.siriAuthorizationStatus() == .authorized {
      let vocabulary = INVocabulary.shared()
      vocabulary.setVocabularyStrings(NSOrderedSet(array: titles), of: .mediaAudiobookTitle)
      vocabulary.setVocabularyStrings(NSOrderedSet(array: authors), of: .mediaAudiobookAuthorName)
      vocabulary.setVocabularyStrings(NSOrderedSet(array: shows), of: .mediaShowTitle)
    }

    if let upNext = args["upNext"] as? [[String: Any]] {
      let intents = upNext.compactMap(playIntent(for:))
      INUpcomingMediaManager.shared.setSuggestedMediaIntents(NSOrderedSet(array: intents))
    }

    if #available(iOS 17.0, *) {
      AbsorbSiriShortcuts.updateAppShortcutParameters()
    }
    SiriBridge.shared.log("library updated: \(count) items, \(titles.count) titles, \(authors.count) authors, \(shows.count) shows")
  }

  static func donate(_ args: [String: Any]) {
    guard let intent = playIntent(for: args) else { return }
    let response = INPlayMediaIntentResponse(code: .success, userActivity: nil)
    INInteraction(intent: intent, response: response).donate { error in
      if let error {
        SiriBridge.shared.log("donate failed: \(error.localizedDescription)")
      }
    }
  }

  static func playIntent(for item: [String: Any]) -> INPlayMediaIntent? {
    guard let mediaItem = mediaItem(item) else { return nil }
    return INPlayMediaIntent(
      mediaItems: [mediaItem],
      mediaContainer: nil,
      playShuffled: nil,
      playbackRepeatMode: .unknown,
      resumePlayback: true,
      playbackQueueLocation: .now,
      playbackSpeed: nil,
      mediaSearch: nil
    )
  }

  static func mediaItem(_ item: [String: Any]) -> INMediaItem? {
    guard let id = item["id"] as? String, !id.isEmpty else { return nil }
    let title = item["title"] as? String ?? ""
    let type: INMediaItemType
    switch item["kind"] as? String {
    case "podcast": type = .podcastShow
    case "episode": type = .podcastEpisode
    default: type = .audioBook
    }
    let author = (item["author"] as? String).flatMap { $0.isEmpty ? nil : $0 }
    return INMediaItem(
      identifier: id,
      title: title.isEmpty ? nil : title,
      type: type,
      artwork: artwork(item["coverPath"] as? String),
      artist: author
    )
  }

  private static func artwork(_ path: String?) -> INImage? {
    guard let path, FileManager.default.fileExists(atPath: path),
          let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
          data.count < 3_000_000
    else { return nil }
    return INImage(imageData: data)
  }

  /// The catalog Dart last wrote to the app group, for when Dart can't
  /// answer in time and for the Shortcuts app's book picker.
  static func catalog() -> [[String: Any]] {
    guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: absorbAppGroup),
          let data = try? Data(contentsOf: dir.appendingPathComponent(catalogFileName)),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let entries = json["entries"] as? [[String: Any]]
    else { return [] }
    return entries
  }

  static func normalize(_ s: String) -> String {
    let folded = s.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    let words = folded.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
    var joined = words.joined(separator: " ")
    for article in ["the ", "a ", "an "] where joined.hasPrefix(article) {
      joined.removeFirst(article.count)
      break
    }
    return joined
  }

  /// Plain title and author matching against the catalog, used only when Dart
  /// didn't answer in time.
  static func search(name: String?, artist: String?, type: String) -> [[String: Any]] {
    let query = normalize(name ?? artist ?? "")
    if query.isEmpty { return [] }
    let byAuthor = name == nil
    func fits(_ entry: [String: Any], _ type: String) -> Bool {
      let kind = entry["kind"] as? String ?? "book"
      switch type {
      case "book": return kind == "book" || kind == "series"
      case "podcast", "episode": return kind == "podcast" || kind == "episode"
      default: return true
      }
    }
    // Siri's media type is often its own guess (a book title it also knows as
    // a podcast show comes in as a podcast), so it only orders the hits,
    // unless "podcast" or "episode" was said.
    let saysPodcast = (name ?? "").range(
      of: #"\b(podcast|episode)s?\b"#, options: [.regularExpression, .caseInsensitive]) != nil
    let hits = catalog().filter { entry in
      if saysPodcast && !fits(entry, "podcast") { return false }
      let field = normalize(entry[byAuthor ? "author" : "title"] as? String ?? "")
      return !field.isEmpty && (field == query || field.contains(query))
    }
    let exact = hits.filter { normalize($0[byAuthor ? "author" : "title"] as? String ?? "") == query }
    let pool = exact.isEmpty ? hits : exact
    let ordered = pool.filter { fits($0, type) } + pool.filter { !fits($0, type) }
    return Array(ordered.prefix(4))
  }
}

/// "Play Project Hail Mary on Absorb", "Play the latest episode of The Daily
/// on Absorb", "Resume Absorb". Handled in the app process, so the audio can
/// start straight from here.
final class SiriMediaHandler: NSObject, INPlayMediaIntentHandling {
  static let shared = SiriMediaHandler()

  private func log(_ line: String) {
    SiriBridge.shared.log(line)
  }

  private static func typeName(_ type: INMediaItemType?) -> String {
    switch type {
    case .audioBook?: return "book"
    case .podcastShow?, .podcastPlaylist?, .podcastStation?: return "podcast"
    case .podcastEpisode?: return "episode"
    default: return "any"
    }
  }

  func resolveMediaItems(
    for intent: INPlayMediaIntent,
    with completion: @escaping ([INPlayMediaMediaItemResolutionResult]) -> Void
  ) {
    if let chosen = intent.mediaItems, let first = chosen.first {
      completion([INPlayMediaMediaItemResolutionResult.success(with: first)])
      return
    }
    let search = intent.mediaSearch
    var args: [String: Any] = ["type": Self.typeName(search?.mediaType)]
    if search?.reference != .currentlyPlaying {
      if let name = search?.mediaName, !name.isEmpty { args["name"] = name }
      if let artist = search?.artistName, !artist.isEmpty { args["artist"] = artist }
    }
    if search?.sortOrder == .newest { args["latest"] = true }
    log("resolve name=\(args["name"] ?? "-") artist=\(args["artist"] ?? "-") type=\(args["type"] ?? "-")")

    SiriBridge.shared.call("resolve", args, timeout: 8) { reply, _ in
      guard let reply else {
        completion(self.resolveNatively(args))
        return
      }
      let items = (reply["items"] as? [[String: Any]] ?? []).compactMap(SiriLibrary.mediaItem)
      let status = reply["status"] as? String ?? "none"
      self.log("resolve -> \(status) \(items.compactMap { $0.title }.joined(separator: " | "))")
      switch status {
      case "ok" where !items.isEmpty:
        completion([INPlayMediaMediaItemResolutionResult.success(with: items[0])])
      case "ambiguous" where items.count > 1:
        completion([INPlayMediaMediaItemResolutionResult.disambiguation(with: items)])
      case "ambiguous" where items.count == 1:
        completion([INPlayMediaMediaItemResolutionResult.success(with: items[0])])
      case "signedOut":
        completion([INPlayMediaMediaItemResolutionResult.unsupported(forReason: .loginRequired)])
      default:
        completion([INPlayMediaMediaItemResolutionResult.unsupported()])
      }
    }
  }

  /// Dart didn't answer in time: resume the stashed book, or match the
  /// catalog from the last run by plain text.
  private func resolveNatively(_ args: [String: Any]) -> [INPlayMediaMediaItemResolutionResult] {
    let name = args["name"] as? String
    let artist = args["artist"] as? String
    if name == nil && artist == nil {
      let defaults = UserDefaults(suiteName: absorbAppGroup)
      guard defaults?.string(forKey: "np_item_id") != nil else {
        return [INPlayMediaMediaItemResolutionResult.unsupported()]
      }
      let item = INMediaItem(
        identifier: "resume",
        title: defaults?.string(forKey: "np_title"),
        type: .audioBook,
        artwork: nil,
        artist: defaults?.string(forKey: "np_author")
      )
      return [INPlayMediaMediaItemResolutionResult.success(with: item)]
    }
    let hits = SiriLibrary.search(name: name, artist: artist, type: args["type"] as? String ?? "any")
      .compactMap(SiriLibrary.mediaItem)
    log("resolve natively -> \(hits.count) match(es)")
    if hits.count == 1 { return [INPlayMediaMediaItemResolutionResult.success(with: hits[0])] }
    if hits.count > 1 { return [INPlayMediaMediaItemResolutionResult.disambiguation(with: hits)] }
    return [INPlayMediaMediaItemResolutionResult.unsupported()]
  }

  func resolvePlaybackSpeed(
    for intent: INPlayMediaIntent,
    with completion: @escaping (INPlayMediaPlaybackSpeedResolutionResult) -> Void
  ) {
    guard let speed = intent.playbackSpeed else {
      completion(INPlayMediaPlaybackSpeedResolutionResult.notRequired())
      return
    }
    completion(INPlayMediaPlaybackSpeedResolutionResult.success(with: min(max(speed, 0.5), 5.0)))
  }

  func handle(intent: INPlayMediaIntent, completion: @escaping (INPlayMediaIntentResponse) -> Void) {
    let id = intent.mediaItems?.first?.identifier ?? "resume"
    var args: [String: Any] = ["id": id]
    if let speed = intent.playbackSpeed { args["speed"] = speed }
    if intent.mediaSearch?.sortOrder == .newest { args["latest"] = true }
    log("handle \(id)")

    // Siri only grants the background audio start for a short while; hold
    // the session open now so the play that follows isn't refused.
    absorbClaimOwnershipIfOwnerDead()
    activateAbsorbAudioSession()

    if !SiriBridge.shared.dartReady && (id == "resume" || Self.isStashed(id)) {
      log("handle \(id): Dart is still starting, resuming from the native player")
      AbsorbPlayerCore.shared.play()
      completion(INPlayMediaIntentResponse(code: .success, userActivity: nil))
      return
    }

    SiriBridge.shared.call("play", args, timeout: 12) { reply, sent in
      if let reply {
        let ok = reply["ok"] as? Bool ?? false
        self.log("handle \(id) -> ok=\(ok)")
        completion(INPlayMediaIntentResponse(code: ok ? .success : .failure, userActivity: nil))
      } else if sent {
        // Under way but slow (a stream still buffering): let Siri finish.
        completion(INPlayMediaIntentResponse(code: .success, userActivity: nil))
      } else if id == "resume" {
        AbsorbPlayerCore.shared.play()
        completion(INPlayMediaIntentResponse(code: .success, userActivity: nil))
      } else {
        completion(INPlayMediaIntentResponse(code: .failureRequiringAppLaunch, userActivity: nil))
      }
    }
  }

  /// The book the native player can start with no help from Dart.
  private static func isStashed(_ id: String) -> Bool {
    let parts = id.split(separator: "|", omittingEmptySubsequences: false).map(String.init)
    guard parts.count >= 2, parts[0] == "book" || parts[0] == "episode" else { return false }
    let defaults = UserDefaults(suiteName: absorbAppGroup)
    guard defaults?.string(forKey: "np_item_id") == parts[1] else { return false }
    let stashedEpisode = defaults?.string(forKey: "np_episode_id") ?? ""
    let episode = parts.count > 2 ? parts[2] : ""
    return stashedEpisode == episode
  }
}
