import AbsorbPlayerCore
import AppIntents
import Foundation

@available(iOS 16.0, *)
enum SiriIntentError: Error, CustomLocalizedStringResourceConvertible {
  case nothingPlaying
  case nothingToResume
  case noTimer
  case notAnswering
  case couldNotPlay

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .nothingPlaying: return "Nothing is playing in Absorb."
    case .nothingToResume: return "There's nothing to resume in Absorb yet."
    case .noTimer: return "There's no sleep timer running."
    case .notAnswering: return "Absorb didn't answer in time. Try again in a moment."
    case .couldNotPlay: return "Absorb couldn't start that book."
    }
  }
}

/// Runs a player action through Dart, or through the native player while Dart
/// is still starting (only resume, pause and the skips work there).
@available(iOS 16.0, *)
enum SiriControl {
  static func run(
    _ action: String,
    _ extra: [String: Any] = [:],
    native: (() -> Void)? = nil
  ) async -> [String: Any]? {
    if !SiriBridge.shared.dartReady, let native {
      SiriBridge.shared.log("\(action): Dart is still starting, using the native player")
      native()
      return ["ok": true]
    }
    var args = extra
    args["action"] = action
    let reply: [String: Any]? = await withCheckedContinuation { continuation in
      SiriBridge.shared.call("control", args, timeout: 10) { reply, _ in
        continuation.resume(returning: reply)
      }
    }
    return reply
  }

  static func requireOk(_ reply: [String: Any]?, orElse error: SiriIntentError) throws -> [String: Any] {
    guard let reply else { throw SiriIntentError.notAnswering }
    guard reply["ok"] as? Bool == true else { throw error }
    return reply
  }

  static var skipBackSeconds: Int {
    let s = UserDefaults(suiteName: absorbAppGroup)?.integer(forKey: "widget_skip_back") ?? 0
    return s > 0 ? s : 10
  }

  static var skipForwardSeconds: Int {
    let s = UserDefaults(suiteName: absorbAppGroup)?.integer(forKey: "widget_skip_forward") ?? 0
    return s > 0 ? s : 30
  }

  static func spokenDuration(_ seconds: Int) -> String {
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    func unit(_ n: Int, _ word: String) -> String { "\(n) \(word)\(n == 1 ? "" : "s")" }
    if hours > 0 && minutes > 0 { return "\(unit(hours, "hour")) and \(unit(minutes, "minute"))" }
    if hours > 0 { return unit(hours, "hour") }
    return unit(max(minutes, 1), "minute")
  }
}

@available(iOS 16.0, *)
struct ResumeListeningIntent: AudioPlaybackIntent {
  static let title: LocalizedStringResource = "Resume Listening"
  static let description = IntentDescription("Picks up the book or episode you were last listening to.")
  static let openAppWhenRun = false

  init() {}

  func perform() async throws -> some IntentResult {
    absorbClaimOwnershipIfOwnerDead()
    activateAbsorbAudioSession()
    let reply = await SiriControl.run("resume") { AbsorbPlayerCore.shared.play() }
    _ = try SiriControl.requireOk(reply, orElse: .nothingToResume)
    return .result()
  }
}

@available(iOS 16.0, *)
struct PauseListeningIntent: AudioPlaybackIntent {
  static let title: LocalizedStringResource = "Pause Listening"
  static let description = IntentDescription("Pauses what Absorb is playing.")
  static let openAppWhenRun = false

  init() {}

  func perform() async throws -> some IntentResult {
    let reply = await SiriControl.run("pause") { AbsorbPlayerCore.shared.pause() }
    _ = try SiriControl.requireOk(reply, orElse: .nothingPlaying)
    return .result()
  }
}

@available(iOS 16.0, *)
struct SkipBackIntent: AudioPlaybackIntent {
  static let title: LocalizedStringResource = "Skip Back"
  static let description = IntentDescription("Skips back by your skip amount.")
  static let openAppWhenRun = false

  init() {}

  func perform() async throws -> some IntentResult {
    let reply = await SiriControl.run("skipBack") {
      AbsorbPlayerCore.shared.skipBackward(seconds: SiriControl.skipBackSeconds)
    }
    _ = try SiriControl.requireOk(reply, orElse: .nothingPlaying)
    return .result()
  }
}

@available(iOS 16.0, *)
struct SkipForwardIntent: AudioPlaybackIntent {
  static let title: LocalizedStringResource = "Skip Forward"
  static let description = IntentDescription("Skips forward by your skip amount.")
  static let openAppWhenRun = false

  init() {}

  func perform() async throws -> some IntentResult {
    let reply = await SiriControl.run("skipForward") {
      AbsorbPlayerCore.shared.skipForward(seconds: SiriControl.skipForwardSeconds)
    }
    _ = try SiriControl.requireOk(reply, orElse: .nothingPlaying)
    return .result()
  }
}

@available(iOS 16.0, *)
struct NextChapterIntent: AudioPlaybackIntent {
  static let title: LocalizedStringResource = "Next Chapter"
  static let description = IntentDescription("Jumps to the next chapter.")
  static let openAppWhenRun = false

  init() {}

  func perform() async throws -> some IntentResult {
    let reply = await SiriControl.run("nextChapter")
    _ = try SiriControl.requireOk(reply, orElse: .nothingPlaying)
    return .result()
  }
}

@available(iOS 16.0, *)
struct PreviousChapterIntent: AudioPlaybackIntent {
  static let title: LocalizedStringResource = "Previous Chapter"
  static let description = IntentDescription("Jumps back to the start of the chapter, or the one before.")
  static let openAppWhenRun = false

  init() {}

  func perform() async throws -> some IntentResult {
    let reply = await SiriControl.run("previousChapter")
    _ = try SiriControl.requireOk(reply, orElse: .nothingPlaying)
    return .result()
  }
}

@available(iOS 16.0, *)
struct SetSleepTimerIntent: AppIntent {
  static let title: LocalizedStringResource = "Set Sleep Timer"
  static let description = IntentDescription("Stops playback after the time you choose.")
  static let openAppWhenRun = false

  @Parameter(
    title: "Duration",
    description: "How long to keep playing",
    defaultValue: 30,
    defaultUnit: .minutes,
    supportsNegativeNumbers: false
  )
  var duration: Measurement<UnitDuration>

  static var parameterSummary: some ParameterSummary {
    Summary("Set a sleep timer for \(\.$duration)")
  }

  init() {}

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let minutes = Int((duration.converted(to: .minutes).value).rounded())
    guard minutes > 0 else { throw SiriIntentError.nothingPlaying }
    let reply = await SiriControl.run("sleepMinutes", ["minutes": minutes])
    _ = try SiriControl.requireOk(reply, orElse: .nothingPlaying)
    let message = "Sleep timer set for \(SiriControl.spokenDuration(minutes * 60))."
    return .result(dialog: IntentDialog(stringLiteral: message))
  }
}

@available(iOS 16.0, *)
struct SleepAtChapterEndIntent: AppIntent {
  static let title: LocalizedStringResource = "Sleep at End of Chapter"
  static let description = IntentDescription("Stops playback when the current chapter ends.")
  static let openAppWhenRun = false

  init() {}

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let reply = await SiriControl.run("sleepChapterEnd")
    _ = try SiriControl.requireOk(reply, orElse: .nothingPlaying)
    return .result(dialog: "Absorb will stop at the end of this chapter.")
  }
}

@available(iOS 16.0, *)
struct CancelSleepTimerIntent: AppIntent {
  static let title: LocalizedStringResource = "Cancel Sleep Timer"
  static let description = IntentDescription("Turns off the sleep timer.")
  static let openAppWhenRun = false

  init() {}

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let reply = await SiriControl.run("cancelSleep")
    _ = try SiriControl.requireOk(reply, orElse: .noTimer)
    return .result(dialog: "Sleep timer off.")
  }
}

@available(iOS 16.0, *)
struct AddBookmarkIntent: AppIntent {
  static let title: LocalizedStringResource = "Add Bookmark"
  static let description = IntentDescription("Bookmarks where you are in the book.")
  static let openAppWhenRun = false

  init() {}

  func perform() async throws -> some IntentResult & ProvidesDialog {
    let reply = await SiriControl.run("bookmark")
    _ = try SiriControl.requireOk(reply, orElse: .nothingPlaying)
    return .result(dialog: "Bookmarked.")
  }
}

@available(iOS 16.0, *)
struct WhatsPlayingIntent: AppIntent {
  static let title: LocalizedStringResource = "What's Playing"
  static let description = IntentDescription("Tells you the book, chapter and time left.")
  static let openAppWhenRun = false

  init() {}

  func perform() async throws -> some IntentResult & ProvidesDialog {
    var title = "", author = "", chapter = ""
    var position = 0, duration = 0
    if SiriBridge.shared.dartReady,
       let reply = await SiriControl.run("status"),
       reply["hasBook"] as? Bool == true {
      title = reply["title"] as? String ?? ""
      author = reply["author"] as? String ?? ""
      chapter = reply["chapter"] as? String ?? ""
      position = reply["position"] as? Int ?? 0
      duration = reply["duration"] as? Int ?? 0
    } else {
      let defaults = UserDefaults(suiteName: absorbAppGroup)
      title = defaults?.string(forKey: "np_title") ?? ""
      author = defaults?.string(forKey: "np_author") ?? ""
      position = Int(defaults?.double(forKey: "np_position_s") ?? 0)
      duration = Int(defaults?.double(forKey: "np_total_s") ?? 0)
    }
    guard !title.isEmpty else { throw SiriIntentError.nothingPlaying }
    var message = author.isEmpty ? "You're listening to \(title)." : "You're listening to \(title) by \(author)."
    if !chapter.isEmpty && chapter != title { message += " \(chapter)." }
    if duration > position && duration > 0 {
      message += " \(SiriControl.spokenDuration(duration - position)) left."
    }
    return .result(dialog: IntentDialog(stringLiteral: message))
  }
}

/// A book or show from the list Dart keeps for Siri, for the Shortcuts app.
@available(iOS 16.0, *)
struct AbsorbBookEntity: AppEntity {
  static var typeDisplayRepresentation: TypeDisplayRepresentation = "Book"
  static var defaultQuery = AbsorbBookQuery()

  var id: String
  var title: String
  var author: String

  var displayRepresentation: DisplayRepresentation {
    author.isEmpty
      ? DisplayRepresentation(title: "\(title)")
      : DisplayRepresentation(title: "\(title)", subtitle: "\(author)")
  }

  init(id: String, title: String, author: String) {
    self.id = id
    self.title = title
    self.author = author
  }

  init?(_ entry: [String: Any]) {
    guard let id = entry["id"] as? String, let title = entry["title"] as? String, !title.isEmpty else { return nil }
    self.init(id: id, title: title, author: entry["author"] as? String ?? "")
  }
}

@available(iOS 16.0, *)
struct AbsorbBookQuery: EntityStringQuery {
  init() {}

  private static func playable() -> [AbsorbBookEntity] {
    SiriLibrary.catalog().compactMap { entry in
      (entry["kind"] as? String) == "episode" ? nil : AbsorbBookEntity(entry)
    }
  }

  func entities(for identifiers: [AbsorbBookEntity.ID]) async throws -> [AbsorbBookEntity] {
    let wanted = Set(identifiers)
    return Self.playable().filter { wanted.contains($0.id) }
  }

  func entities(matching string: String) async throws -> [AbsorbBookEntity] {
    let query = SiriLibrary.normalize(string)
    guard !query.isEmpty else { return [] }
    return Self.playable().filter {
      SiriLibrary.normalize($0.title).contains(query) || SiriLibrary.normalize($0.author).contains(query)
    }
  }

  func suggestedEntities() async throws -> [AbsorbBookEntity] {
    Array(Self.playable().prefix(50))
  }
}

@available(iOS 16.0, *)
struct PlayBookIntent: AudioPlaybackIntent {
  static let title: LocalizedStringResource = "Play Book"
  static let description = IntentDescription("Plays a book, series or podcast from your library.")
  static let openAppWhenRun = false

  @Parameter(title: "Book")
  var book: AbsorbBookEntity

  static var parameterSummary: some ParameterSummary {
    Summary("Play \(\.$book)")
  }

  init() {}

  init(book: AbsorbBookEntity) {
    self.book = book
  }

  func perform() async throws -> some IntentResult {
    absorbClaimOwnershipIfOwnerDead()
    activateAbsorbAudioSession()
    let id = book.id
    let reply: ([String: Any]?, Bool) = await withCheckedContinuation { continuation in
      SiriBridge.shared.call("play", ["id": id], timeout: 12) { reply, sent in
        continuation.resume(returning: (reply, sent))
      }
    }
    if let result = reply.0 {
      guard result["ok"] as? Bool == true else { throw SiriIntentError.couldNotPlay }
    } else if !reply.1 {
      throw SiriIntentError.notAnswering
    }
    return .result()
  }
}

@available(iOS 17.0, *)
struct AbsorbSiriShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: ResumeListeningIntent(),
      phrases: [
        "Resume \(.applicationName)",
        "Continue \(.applicationName)",
        "Resume listening in \(.applicationName)",
        "Continue listening in \(.applicationName)",
        "Play my audiobook in \(.applicationName)",
        "Play my book in \(.applicationName)",
        "Continue my book in \(.applicationName)",
        "Resume my podcast in \(.applicationName)",
      ],
      shortTitle: "Resume",
      systemImageName: "play.fill"
    )
    AppShortcut(
      intent: PauseListeningIntent(),
      phrases: [
        "Pause \(.applicationName)",
        "Pause listening in \(.applicationName)",
        "Stop \(.applicationName)",
      ],
      shortTitle: "Pause",
      systemImageName: "pause.fill"
    )
    AppShortcut(
      intent: SkipBackIntent(),
      phrases: [
        "Skip back in \(.applicationName)",
        "Go back in \(.applicationName)",
        "Rewind \(.applicationName)",
      ],
      shortTitle: "Skip Back",
      systemImageName: "gobackward"
    )
    AppShortcut(
      intent: SkipForwardIntent(),
      phrases: [
        "Skip forward in \(.applicationName)",
        "Skip ahead in \(.applicationName)",
        "Fast forward \(.applicationName)",
      ],
      shortTitle: "Skip Forward",
      systemImageName: "goforward"
    )
    AppShortcut(
      intent: NextChapterIntent(),
      phrases: [
        "Next chapter in \(.applicationName)",
        "Skip to the next chapter in \(.applicationName)",
      ],
      shortTitle: "Next Chapter",
      systemImageName: "forward.end.fill"
    )
    AppShortcut(
      intent: PreviousChapterIntent(),
      phrases: [
        "Previous chapter in \(.applicationName)",
        "Go back a chapter in \(.applicationName)",
      ],
      shortTitle: "Previous Chapter",
      systemImageName: "backward.end.fill"
    )
    AppShortcut(
      intent: SetSleepTimerIntent(),
      phrases: [
        "Set a sleep timer in \(.applicationName)",
        "Set sleep timer in \(.applicationName)",
        "Start a sleep timer in \(.applicationName)",
      ],
      shortTitle: "Sleep Timer",
      systemImageName: "moon.zzz.fill"
    )
    AppShortcut(
      intent: CancelSleepTimerIntent(),
      phrases: [
        "Cancel the sleep timer in \(.applicationName)",
        "Turn off the sleep timer in \(.applicationName)",
      ],
      shortTitle: "Cancel Sleep Timer",
      systemImageName: "moon"
    )
    AppShortcut(
      intent: AddBookmarkIntent(),
      phrases: [
        "Add a bookmark in \(.applicationName)",
        "Bookmark this in \(.applicationName)",
        "Bookmark \(.applicationName)",
      ],
      shortTitle: "Add Bookmark",
      systemImageName: "bookmark.fill"
    )
    AppShortcut(
      intent: WhatsPlayingIntent(),
      phrases: [
        "What's playing in \(.applicationName)",
        "What am I listening to in \(.applicationName)",
        "How much is left in \(.applicationName)",
      ],
      shortTitle: "What's Playing",
      systemImageName: "info.circle"
    )
  }
}
