import ActivityKit
import Foundation

/// The book's Live Activity: a lock screen and Dynamic Island card shown while
/// the book mixes with another app's audio. iOS gives the system media
/// controls only to a session that doesn't mix, so while mixing they belong to
/// the other app and this card is how the book stays in reach. Shared by the
/// app, which starts and updates it, and the widget extension, which draws it.
@available(iOS 16.1, *)
public struct AbsorbBookActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    /// What the widgets show as the title: the chapter for most books.
    public var title: String
    /// "Author · Book", as the widgets show it.
    public var subtitle: String
    public var isPlaying: Bool
    /// Book position at `asOf`, in book seconds.
    public var positionS: Double
    /// The progress bar's range: the chapter in chapter-progress mode,
    /// otherwise the whole book.
    public var segStartS: Double
    public var segEndS: Double
    public var speed: Double
    public var asOf: Date
    /// Cover file in the app group container; the extension decodes it.
    public var coverPath: String
    public var skipBack: Int
    public var skipForward: Int

    public init(title: String, subtitle: String, isPlaying: Bool, positionS: Double,
                segStartS: Double, segEndS: Double, speed: Double, asOf: Date,
                coverPath: String, skipBack: Int, skipForward: Int) {
      self.title = title
      self.subtitle = subtitle
      self.isPlaying = isPlaying
      self.positionS = positionS
      self.segStartS = segStartS
      self.segEndS = segEndS
      self.speed = speed
      self.asOf = asOf
      self.coverPath = coverPath
      self.skipBack = skipBack
      self.skipForward = skipForward
    }

    /// Where playback is expected to be at `date`.
    public func projectedPosition(at date: Date) -> Double {
      guard isPlaying else { return positionS }
      return positionS + date.timeIntervalSince(asOf) * speed
    }

    /// Wall-clock span over which a running bar crosses the segment at the
    /// current speed, for `ProgressView(timerInterval:)`, which then animates
    /// without further updates.
    public var segmentWallClock: ClosedRange<Date> {
      let rate = speed > 0 ? speed : 1
      let start = asOf.addingTimeInterval(-(positionS - segStartS) / rate)
      let end = asOf.addingTimeInterval((segEndS - positionS) / rate)
      return start...max(start, end)
    }
  }

  public var itemId: String

  public init(itemId: String) {
    self.itemId = itemId
  }
}
