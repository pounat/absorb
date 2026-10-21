import AbsorbPlayerCore
import ActivityKit
import AVFoundation
import UIKit
import WidgetKit

/// Starts, updates and ends the book's Live Activity. The card exists only
/// while the book mixes with another app's audio: alone, the book holds the
/// system media controls and the card would repeat them.
///
/// iOS lets an app start a Live Activity only while it is in the foreground;
/// updating and ending work from the background, so a card started in the app
/// follows the book from then on. Its state comes from the same app-group keys
/// the home screen widgets read, plus the engine's own play state and position.
enum BookLiveActivityController {
  static var logSink: ((String) -> Void)?

  /// Safe to call often: only a visible change reaches ActivityKit, whose
  /// update budget is limited. The progress bar runs on its own between.
  static func refresh(reason: String) {
    guard #available(iOS 16.2, *) else { return }
    DispatchQueue.main.async { refreshOnMain(reason: reason) }
  }

  @available(iOS 16.2, *)
  private static func refreshOnMain(reason: String) {
    let activities = Activity<AbsorbBookActivityAttributes>.activities
    let defaults = UserDefaults(suiteName: absorbAppGroup)
    let itemId = defaults?.string(forKey: "np_item_id") ?? ""
    let mixing = AVAudioSession.sharedInstance().categoryOptions.contains(.mixWithOthers)
    let wanted = mixing
      && (defaults?.bool(forKey: "widget_has_book") ?? false)
      && !itemId.isEmpty
      && ActivityAuthorizationInfo().areActivitiesEnabled

    for activity in activities where !wanted || activity.attributes.itemId != itemId {
      Task { await activity.end(nil, dismissalPolicy: .immediate) }
      log("ended (\(reason)): mixing=\(mixing)")
    }
    if #available(iOS 18.0, *) {
      ControlCenter.shared.reloadControls(ofKind: "AbsorbPlayPauseControl")
    }
    guard wanted else { return }

    let state = currentState(defaults)
    if let current = activities.first(where: {
      $0.attributes.itemId == itemId && $0.activityState == .active
    }) {
      guard needsUpdate(from: current.content.state, to: state) else { return }
      Task { await current.update(ActivityContent(state: state, staleDate: nil)) }
      log("updated (\(reason)): playing=\(state.isPlaying)")
    } else if UIApplication.shared.applicationState == .active, state.isPlaying {
      do {
        _ = try Activity.request(
          attributes: AbsorbBookActivityAttributes(itemId: itemId),
          content: ActivityContent(state: state, staleDate: nil),
          pushType: nil)
        log("started (\(reason))")
      } catch {
        log("start failed (\(reason)): \(error.localizedDescription)")
      }
    }
  }

  @available(iOS 16.2, *)
  private static func currentState(_ d: UserDefaults?) -> AbsorbBookActivityAttributes.ContentState {
    let engine = AbsorbAudioEngine.shared
    let displayTotal = d?.double(forKey: "np_display_total_s") ?? 0
    let total = displayTotal > 0 ? displayTotal : (d?.double(forKey: "np_total_s") ?? 0)
    var pos = engine.globalPositionS()
    if !pos.isFinite || pos <= 0, let stored = d?.object(forKey: "np_position_s") as? Double {
      pos = stored
    }
    pos = max(0, total > 0 ? min(pos, total) : pos)

    var segStart = 0.0
    var segEnd = total
    if d?.bool(forKey: "widget_chapter_mode") ?? false, let ch = chapter(at: pos, d) {
      segStart = ch.start
      segEnd = ch.end
    }
    let speed = d?.double(forKey: "np_speed") ?? 1
    let skipBack = d?.integer(forKey: "widget_skip_back") ?? 0
    let skipForward = d?.integer(forKey: "widget_skip_forward") ?? 0
    return .init(
      title: d?.string(forKey: "widget_title") ?? "",
      subtitle: d?.string(forKey: "widget_author") ?? "",
      isPlaying: engine.isPlaying,
      positionS: pos,
      segStartS: segStart,
      segEndS: max(segStart, segEnd),
      speed: speed > 0 ? speed : 1,
      asOf: Date(),
      coverPath: d?.string(forKey: "widget_cover_path") ?? "",
      skipBack: skipBack > 0 ? skipBack : 10,
      skipForward: skipForward > 0 ? skipForward : 30)
  }

  /// Chapter containing `pos`, read the way the home screen widget reads it.
  private static func chapter(at pos: Double, _ d: UserDefaults?) -> (start: Double, end: Double)? {
    guard let json = d?.string(forKey: "np_chapters_json"),
          let data = json.data(using: .utf8),
          let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return nil }
    let chapters: [(start: Double, end: Double)] = raw.compactMap { m in
      guard let s = (m["start"] as? NSNumber)?.doubleValue,
            let e = (m["end"] as? NSNumber)?.doubleValue, e > s else { return nil }
      return (s, e)
    }
    guard !chapters.isEmpty else { return nil }
    for c in chapters where pos >= c.start && pos < c.end { return c }
    return pos > 0 ? chapters.last : chapters.first
  }

  @available(iOS 16.2, *)
  private static func needsUpdate(from old: AbsorbBookActivityAttributes.ContentState,
                                  to new: AbsorbBookActivityAttributes.ContentState) -> Bool {
    if old.isPlaying != new.isPlaying || old.title != new.title || old.subtitle != new.subtitle
      || old.coverPath != new.coverPath || old.segStartS != new.segStartS
      || old.segEndS != new.segEndS || old.speed != new.speed
      || old.skipBack != new.skipBack || old.skipForward != new.skipForward {
      return true
    }
    // A seek, or drift the projection didn't foresee (a stall).
    return abs(old.projectedPosition(at: new.asOf) - new.positionS) > 3
  }

  private static func log(_ line: String) {
    NSLog("[LiveActivity] %@", line)
    logSink?("[LiveActivity] \(line)")
  }
}
