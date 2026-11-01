import AbsorbPlayerCore
import AppIntents
import WidgetKit
import SwiftUI
import AVFAudio
import ImageIO

private let appGroup = "group.com.barnabas.absorb"

// Deep-link URL used only by the play button when no session is loaded, so
// the app launches and can cold-resume the last-played item. Must use the
// registered URL scheme (audiobookshelf://) and include ?homeWidget so the
// home_widget Flutter plugin intercepts the URL on launch.
private let playPauseURL = URL(string: "audiobookshelf://widget/play_pause?homeWidget")!

// Intents (AbsorbPlayPauseIntent / AbsorbSkipBackIntent /
// AbsorbSkipForwardIntent) live in the AbsorbPlayerCore Swift package so
// both Runner and this extension see the same Swift type. Without that,
// AppDependencyManager registrations made in Runner's AppDelegate can't
// resolve in widget-process intent invocations, the @Dependency throws,
// and only the optimistic UI flip in perform() takes effect.

// MARK: - Entry

struct NowPlayingEntry: TimelineEntry {
    let date: Date
    let hasBook: Bool
    let title: String
    let author: String
    let isPlaying: Bool
    /// Absolute book position in seconds.
    let positionS: Double
    /// The progress segment: the whole book normally, the current chapter
    /// when the app's chapter-progress setting is on. Bar fill and the time
    /// labels all run over this range, matching the in-app rows.
    let segStartS: Double
    let segEndS: Double
    /// Whole-book display total (the metadata duration the app's cards show).
    let totalS: Double
    let speed: Double
    let speedAdjusted: Bool
    let coverImage: UIImage?
    let skipBack: Int
    let skipForward: Int

    var progress: Double {
        let len = segEndS - segStartS
        guard len > 0 else { return 0 }
        return min(1, max(0, (positionS - segStartS) / len))
    }

    /// Copy for a projected future timeline entry - same book state, new
    /// date, advanced position, and possibly a new chapter segment/title.
    func at(date: Date, positionS: Double, segStartS: Double, segEndS: Double,
            title: String) -> NowPlayingEntry {
        NowPlayingEntry(
            date: date, hasBook: hasBook, title: title, author: author,
            isPlaying: isPlaying, positionS: positionS,
            segStartS: segStartS, segEndS: segEndS, totalS: totalS,
            speed: speed, speedAdjusted: speedAdjusted, coverImage: coverImage,
            skipBack: skipBack, skipForward: skipForward
        )
    }
}

// Projection cadence for playing timelines, and the freeze horizon for the
// live time labels (two steps: the next entry re-baselines well before it).
private let artProjectionStepS: TimeInterval = 15

struct WChapter {
    let start: Double
    let end: Double
    let title: String
}

func loadChapters(_ d: UserDefaults?) -> [WChapter] {
    guard let json = d?.string(forKey: "np_chapters_json"),
          let data = json.data(using: .utf8),
          let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    else { return [] }
    return raw.compactMap { m in
        guard let s = (m["start"] as? NSNumber)?.doubleValue,
              let e = (m["end"] as? NSNumber)?.doubleValue, e > s else { return nil }
        return WChapter(start: s, end: e, title: (m["title"] as? String) ?? "")
    }
}

/// Chapter containing `pos`, with the app's fallback: past the last end
/// resolves to the last chapter.
func chapterAt(_ pos: Double, in chapters: [WChapter]) -> WChapter? {
    guard !chapters.isEmpty else { return nil }
    for c in chapters where pos >= c.start && pos < c.end { return c }
    return pos > 0 ? chapters.last : chapters.first
}

/// Decode the cover bounded to `maxDimension` px. The art widgets render the
/// cover full-bleed, and decoding a full-resolution cover inside the widget
/// extension's tight memory cap is asking for a jetsam kill.
private func loadCover(path: String, maxDimension: CGFloat) -> UIImage? {
    let url = URL(fileURLWithPath: path)
    let opts: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxDimension,
    ]
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
          let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, opts as CFDictionary) else {
        return UIImage(contentsOfFile: path)
    }
    return UIImage(cgImage: cg)
}

// MARK: - Provider

struct NowPlayingProvider: TimelineProvider {
    func placeholder(in context: Context) -> NowPlayingEntry {
        NowPlayingEntry(
            date: .now, hasBook: true, title: "Audiobook Title",
            author: "Author Name", isPlaying: false, positionS: 10710,
            segStartS: 0, segEndS: 30600, totalS: 30600,
            speed: 1.0, speedAdjusted: true,
            coverImage: nil, skipBack: 10, skipForward: 30
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NowPlayingEntry) -> Void) {
        completion(readSnapshot().entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NowPlayingEntry>) -> Void) {
        let snap = readSnapshot()
        let base = snap.entry

        // Paused or no book: nothing moves, one entry is enough.
        guard base.isPlaying, base.hasBook, base.totalS > 0 else {
            let refreshDate = Date().addingTimeInterval(300)
            completion(Timeline(entries: [base], policy: .after(refreshDate)))
            return
        }

        // Playing: pre-schedule projected entries so the progress bar, the
        // time labels, and the chapter segment advance on their own, at
        // playback speed, without the app running.
        //
        // Projected entries can cross a chapter boundary, so the chapter-as-
        // title label advances too - but only when the stored title already
        // follows the chapter-as-title pattern, so podcast episode titles and
        // chapterless books are left alone.
        let baseChapterTitle = chapterAt(base.positionS, in: snap.chapters)?.title
        let titleFollowsChapters = baseChapterTitle != nil && baseChapterTitle == base.title
        var entries: [NowPlayingEntry] = []
        var t: TimeInterval = 0
        while t <= 30 * 60 && entries.count < 120 {
            let pos = min(base.positionS + t * base.speed, base.totalS)
            var segStart = 0.0
            var segEnd = base.totalS
            var title = base.title
            if let ch = chapterAt(pos, in: snap.chapters) {
                if snap.chapterMode {
                    segStart = ch.start
                    segEnd = ch.end
                }
                if titleFollowsChapters, !ch.title.isEmpty {
                    title = ch.title
                }
            }
            entries.append(base.at(
                date: Date().addingTimeInterval(t),
                positionS: pos, segStartS: segStart, segEndS: segEnd,
                title: title
            ))
            if pos >= base.totalS { break }
            t += artProjectionStepS
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    struct Snapshot {
        let entry: NowPlayingEntry
        let chapters: [WChapter]
        let chapterMode: Bool
    }

    func readSnapshot() -> Snapshot {
        let d = UserDefaults(suiteName: appGroup)
        if d == nil {
            NSLog("[WidgetDebug] readSnapshot: UserDefaults(suiteName:%@) returned nil - app group not accessible from extension", appGroup)
        }
        let hasBook = d?.bool(forKey: "widget_has_book") ?? false
        let title = d?.string(forKey: "widget_title") ?? ""
        let author = d?.string(forKey: "widget_author") ?? ""
        // A stored "playing" can outlive reality (app killed mid-play,
        // overnight jetsam) and used to leave the widget's live timers
        // free-running for hours. Trust it only while something proves audio
        // is actually live: the owning process's Flutter heartbeat, or the
        // native side's activity stamp. The stamp is what lets the icon flip
        // the moment a widget play wakes a suspended app - the heartbeat
        // lags that by many seconds.
        let storedPlaying = d?.bool(forKey: "widget_is_playing") ?? false
        let isPlaying = storedPlaying &&
            (absorbFlutterAlive(pid: absorbAudioOwnerPid()) || absorbAudioActivityFresh())
        // The metadata total the app's cards display; the session total
        // (np_total_s) can differ from it by minutes and is only a fallback.
        let displayTotal = d?.double(forKey: "np_display_total_s") ?? 0
        let totalS = displayTotal > 0 ? displayTotal : (d?.double(forKey: "np_total_s") ?? 0)
        // Absolute position; widget_progress is only a legacy fallback (it
        // follows the notification's chapter-progress mode, so as a book
        // fraction it can be wildly wrong).
        let rawPos = d?.object(forKey: "np_position_s") as? Double ?? -1
        let posS = rawPos >= 0
            ? min(rawPos, totalS > 0 ? totalS : rawPos)
            : Double(d?.integer(forKey: "widget_progress") ?? 0) / 1000.0 * totalS
        let rawSpeed = d?.double(forKey: "np_speed") ?? 1.0
        let speed = rawSpeed > 0 ? rawSpeed : 1.0
        // Default true to match the in-app setting's default.
        let speedAdjusted = d?.object(forKey: "np_speed_adjusted") as? Bool ?? true
        let chapters = loadChapters(d)
        let chapterMode = d?.bool(forKey: "widget_chapter_mode") ?? false
        var segStart = 0.0
        var segEnd = totalS
        if chapterMode, let ch = chapterAt(posS, in: chapters) {
            segStart = ch.start
            segEnd = ch.end
        }
        let skipBack = d?.integer(forKey: "widget_skip_back") ?? 0
        let skipForward = d?.integer(forKey: "widget_skip_forward") ?? 0
        let coverPath = d?.string(forKey: "widget_cover_path") ?? ""

        var cover: UIImage? = nil
        var coverStatus = "empty"
        if !coverPath.isEmpty {
            let exists = FileManager.default.fileExists(atPath: coverPath)
            if !exists {
                coverStatus = "path_missing"
            } else {
                cover = loadCover(path: coverPath, maxDimension: 800)
                coverStatus = cover == nil ? "decode_failed" : "ok"
            }
        }

        NSLog("[WidgetDebug] readSnapshot: hasBook=%@ title=\"%@\" isPlaying=%@ pos=%.1f seg=%.1f-%.1f total=%.1f chapterMode=%@ coverStatus=%@",
              hasBook ? "true" : "false",
              title,
              isPlaying ? "true" : "false",
              posS, segStart, segEnd, totalS,
              chapterMode ? "true" : "false",
              coverStatus)

        let entry = NowPlayingEntry(
            date: .now,
            hasBook: hasBook,
            title: title.isEmpty ? "Absorb" : title,
            author: author.isEmpty ? (hasBook ? "" : "Not playing") : author,
            isPlaying: isPlaying,
            positionS: max(0, posS),
            segStartS: segStart,
            segEndS: segEnd,
            totalS: totalS,
            speed: speed,
            speedAdjusted: speedAdjusted,
            coverImage: cover,
            skipBack: skipBack > 0 ? skipBack : 10,
            skipForward: skipForward > 0 ? skipForward : 30
        )
        return Snapshot(entry: entry, chapters: chapters, chapterMode: chapterMode)
    }
}

// MARK: - Cover Art

private extension Image {
    /// Tinted and Clear home screens flatten an image to one flat color
    /// unless it asks to keep its own (GH #402).
    @ViewBuilder
    func keepingOwnColors() -> some View {
        if #available(iOS 18.0, *) {
            self.widgetAccentedRenderingMode(.fullColor)
        } else {
            self
        }
    }
}

struct CoverArtView: View {
    let image: UIImage?
    let cornerRadius: CGFloat

    var body: some View {
        if let image = image {
            Image(uiImage: image)
                .resizable()
                .keepingOwnColors()
                .aspectRatio(contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        } else {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "book.closed.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: NowPlayingEntry

    var body: some View {
        VStack(spacing: 4) {
            CoverArtView(image: entry.coverImage, cornerRadius: 10)
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)

            Text(entry.title)
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(entry.author)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 18) {
                Button(intent: AbsorbSkipBackIntent()) {
                    Image(systemName: "backward.fill")
                        .font(.title3)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                if entry.hasBook {
                    Button(intent: AbsorbPlayPauseIntent()) {
                        Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title2)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                } else {
                    // No session loaded — tap launches the app so it can
                    // resume the last-played item (AppIntent alone can't
                    // start playback when the app isn't running).
                    Link(destination: playPauseURL) {
                        Image(systemName: "play.fill")
                            .font(.title2)
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                }
                Button(intent: AbsorbSkipForwardIntent()) {
                    Image(systemName: "forward.fill")
                        .font(.title3)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: NowPlayingEntry

    var body: some View {
        HStack(spacing: 12) {
            CoverArtView(image: entry.coverImage, cornerRadius: 12)
                .frame(width: 110, height: 110)

            VStack(alignment: .leading, spacing: 4) {
                Spacer(minLength: 0)

                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)

                Text(entry.author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                HStack(spacing: 28) {
                    Button(intent: AbsorbSkipBackIntent()) {
                        Image(systemName: "backward.fill")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }

                    if entry.hasBook {
                        Button(intent: AbsorbPlayPauseIntent()) {
                            Image(systemName: entry.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .contentShape(Rectangle())
                        }
                    } else {
                        Link(destination: playPauseURL) {
                            Image(systemName: "play.fill")
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .contentShape(Rectangle())
                        }
                    }

                    Button(intent: AbsorbSkipForwardIntent()) {
                        Image(systemName: "forward.fill")
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .contentShape(Rectangle())
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Entry View

struct NowPlayingWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NowPlayingEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        default:
            MediumWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget

struct AbsorbWidget: Widget {
    let kind = "NowPlayingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NowPlayingProvider()) { entry in
            NowPlayingWidgetView(entry: entry)
        }
        .configurationDisplayName("Now Playing")
        .description("See and control your current audiobook.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Cover Art Widget
//
// The iOS take on Android's adaptive tiny widget: the book cover fills the
// whole widget, controls sit on a scrim gradient at the bottom. Small is
// controls only, medium adds title/author, large adds a progress bar with
// elapsed/remaining times.

// SF Symbols ships gobackward.N/goforward.N glyphs only for these values;
// any other configured skip gets the plain arrow with the number overlaid.
private let skipSymbolSeconds: Set<Int> = [5, 10, 15, 30, 45, 60, 75, 90]

private struct ArtSkipIcon: View {
    let forward: Bool
    let seconds: Int
    let size: CGFloat

    var body: some View {
        let base = forward ? "goforward" : "gobackward"
        if skipSymbolSeconds.contains(seconds) {
            Image(systemName: "\(base).\(seconds)")
                .font(.system(size: size, weight: .medium))
        } else {
            ZStack {
                Image(systemName: base)
                    .font(.system(size: size, weight: .medium))
                Text("\(seconds)")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .offset(y: size * 0.06)
            }
        }
    }
}

private struct ArtPlayIcon: View {
    let isPlaying: Bool
    let diameter: CGFloat
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        let glyph = Image(systemName: isPlaying ? "pause.fill" : "play.fill")
            .font(.system(size: diameter * 0.42, weight: .semibold))
        if renderingMode == .accented {
            // A black glyph on a white disc flattens to a blank disc there.
            glyph
                .foregroundStyle(.white)
                .frame(width: diameter, height: diameter)
                .background { Circle().strokeBorder(.white, lineWidth: 1.5) }
        } else {
            glyph
                .foregroundStyle(.black)
                .frame(width: diameter, height: diameter)
                .background(.white, in: Circle())
        }
    }
}

private struct ArtControlsRow: View {
    let entry: NowPlayingEntry
    let playDiameter: CGFloat
    let skipSize: CGFloat
    let spacing: CGFloat

    var body: some View {
        HStack(spacing: spacing) {
            Button(intent: AbsorbSkipBackIntent()) {
                ArtSkipIcon(forward: false, seconds: entry.skipBack, size: skipSize)
                    .frame(width: playDiameter, height: playDiameter)
                    .contentShape(Rectangle())
            }
            if entry.hasBook {
                Button(intent: AbsorbPlayPauseIntent()) {
                    ArtPlayIcon(isPlaying: entry.isPlaying, diameter: playDiameter)
                        .contentShape(Circle())
                }
            } else {
                // No session loaded - launch the app so it can cold-resume.
                Link(destination: playPauseURL) {
                    ArtPlayIcon(isPlaying: false, diameter: playDiameter)
                        .contentShape(Circle())
                }
            }
            Button(intent: AbsorbSkipForwardIntent()) {
                ArtSkipIcon(forward: true, seconds: entry.skipForward, size: skipSize)
                    .frame(width: playDiameter, height: playDiameter)
                    .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
    }
}

// The scrim as a picture: on Tinted and Clear home screens a drawn gradient
// turns into a white haze, an image can keep its black.
private let artScrimImage: UIImage = {
    let size = CGSize(width: 1, height: 256)
    let format = UIGraphicsImageRendererFormat()
    format.opaque = false
    format.scale = 1
    return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
        let colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.65).cgColor,
        ] as CFArray
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: [0.35, 1.0]
        ) else { return }
        ctx.cgContext.drawLinearGradient(
            gradient,
            start: .zero,
            end: CGPoint(x: 0, y: size.height),
            options: []
        )
    }
}()

private struct ArtCoverBackground: View {
    let entry: NowPlayingEntry
    @Environment(\.widgetRenderingMode) private var renderingMode

    var body: some View {
        // GeometryReader pins the filled image to the widget's exact bounds;
        // a bare scaledToFill can overflow the ZStack and stretch the scrim.
        GeometryReader { geo in
            ZStack {
                if let image = entry.coverImage {
                    Image(uiImage: image)
                        .resizable()
                        .keepingOwnColors()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else if renderingMode != .accented {
                    LinearGradient(
                        colors: [Color(white: 0.28), Color(white: 0.10)],
                        startPoint: .top, endPoint: .bottom
                    )
                }
                if renderingMode != .accented {
                    LinearGradient(
                        stops: [
                            .init(color: .black.opacity(0.0), location: 0.35),
                            .init(color: .black.opacity(0.65), location: 1.0),
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                } else if entry.coverImage != nil {
                    Image(uiImage: artScrimImage)
                        .resizable()
                        .keepingOwnColors()
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
    }
}

/// Tinted and Clear home screens throw away a widget's container background,
/// which is where the cover is drawn, so there it goes behind the content.
private struct ArtCoverBacking: ViewModifier {
    let entry: NowPlayingEntry
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.widgetContentMargins) private var margins

    func body(content: Content) -> some View {
        if renderingMode == .accented {
            content
                .background {
                    ArtCoverBackground(entry: entry)
                        .padding(EdgeInsets(
                            top: -margins.top,
                            leading: -margins.leading,
                            bottom: -margins.bottom,
                            trailing: -margins.trailing
                        ))
                        .clipShape(ContainerRelativeShape())
                }
                .containerBackground(for: .widget) { Color.clear }
        } else {
            content
                .containerBackground(for: .widget) { ArtCoverBackground(entry: entry) }
        }
    }
}

private struct ArtProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.28))
                Capsule().fill(.white)
                    .frame(width: max(5, geo.size.width * CGFloat(min(1, max(0, progress)))))
            }
        }
        .frame(height: 5)
    }
}

private func formatClock(_ seconds: Double) -> String {
    let s = max(0, Int(seconds.rounded()))
    let h = s / 3600
    let m = (s % 3600) / 60
    let sec = s % 60
    return h > 0
        ? String(format: "%d:%02d:%02d", h, m, sec)
        : String(format: "%d:%02d", m, sec)
}

private struct ArtSmallView: View {
    let entry: NowPlayingEntry

    var body: some View {
        VStack {
            Spacer()
            ArtControlsRow(entry: entry, playDiameter: 34, skipSize: 15, spacing: 14)
        }
        .frame(maxWidth: .infinity)
        .modifier(ArtCoverBacking(entry: entry))
    }
}

private struct ArtMediumView: View {
    let entry: NowPlayingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Spacer()
            Text(entry.title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
            Text(entry.author)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
            ArtProgressBar(progress: entry.progress)
                .padding(.top, 6)
            ArtControlsRow(entry: entry, playDiameter: 38, skipSize: 16, spacing: 30)
                .frame(maxWidth: .infinity)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ArtCoverBacking(entry: entry))
    }
}

private struct ArtLargeView: View {
    let entry: NowPlayingEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Spacer()
            Text(entry.title)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
            Text(entry.author)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .lineLimit(1)
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
            ArtProgressBar(progress: entry.progress)
                .padding(.top, 8)
            if entry.segEndS > entry.segStartS {
                // Times run over the active segment (whole book, or the
                // current chapter in chapter-progress mode) and mirror the
                // in-app rows exactly: BOTH labels divide by the speed when
                // the Speed-adjusted time setting is on, like the cards do.
                let divisor = entry.speedAdjusted ? max(0.1, entry.speed) : 1.0
                let elapsedShown = max(0, entry.positionS - entry.segStartS) / divisor
                let remainingShown = max(0, entry.segEndS - entry.positionS) / divisor
                // With the divisor applied, both values move at exactly one
                // real second per second at any speed, so both can be live
                // system timers. Raw display at speed != 1 moves faster than
                // real time, which a timer can't do - static per entry then.
                let labelsLive = entry.isPlaying && (entry.speedAdjusted || abs(entry.speed - 1.0) <= 0.01)
                // Live timers tick as long as iOS keeps showing an entry -
                // even if playback died hours ago and no refresh ever came.
                // Freeze them two projection steps past their entry; in
                // normal operation the next entry re-baselines well before
                // that, so this only bites when refreshes stop.
                let pauseAt = entry.date.addingTimeInterval(artProjectionStepS * 2)
                HStack {
                    if labelsLive {
                        Text(timerInterval: entry.date.addingTimeInterval(-elapsedShown)...entry.date.addingTimeInterval(remainingShown),
                             pauseTime: pauseAt, countsDown: false)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        // Timer text reserves an oversized box and left-aligns
                        // its digits inside it, so the countdown needs explicit
                        // trailing alignment or it drifts toward the center.
                        (Text("-") + Text(timerInterval: entry.date...entry.date.addingTimeInterval(remainingShown),
                                          pauseTime: pauseAt, countsDown: true))
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    } else {
                        Text(formatClock(elapsedShown))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("-" + formatClock(remainingShown))
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
                .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
            }
            ArtControlsRow(entry: entry, playDiameter: 44, skipSize: 19, spacing: 38)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(ArtCoverBacking(entry: entry))
    }
}

struct ArtNowPlayingWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: NowPlayingEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                ArtSmallView(entry: entry)
            case .systemLarge:
                ArtLargeView(entry: entry)
            default:
                ArtMediumView(entry: entry)
            }
        }
        // The content always sits on cover art with a dark scrim, so lock the
        // dark palette regardless of the system theme.
        .environment(\.colorScheme, .dark)
    }
}

struct ArtNowPlayingWidget: Widget {
    let kind = "NowPlayingArtWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NowPlayingProvider()) { entry in
            ArtNowPlayingWidgetView(entry: entry)
        }
        .configurationDisplayName("Now Playing Cover")
        .description("Playback controls over the book cover.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Stats Widget

struct StatsEntry: TimelineEntry {
    let date: Date
    let todaySeconds: Int
    let weekSeconds: Int
    let streakDays: Int
    let booksThisYear: Int
}

struct StatsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatsEntry {
        StatsEntry(date: .now, todaySeconds: 1800, weekSeconds: 14400, streakDays: 12, booksThisYear: 8)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> Void) {
        completion(readEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> Void) {
        // Re-read from the app group every 15 minutes. Flutter also pushes a
        // reloadTimelines via home_widget whenever it ticks the counters
        // forward, so in practice the widget refreshes more often.
        let refreshDate = Date().addingTimeInterval(900)
        completion(Timeline(entries: [readEntry()], policy: .after(refreshDate)))
    }

    private func readEntry() -> StatsEntry {
        let d = UserDefaults(suiteName: appGroup)
        let today = d?.integer(forKey: "widget_stats_today") ?? 0
        let week = d?.integer(forKey: "widget_stats_week") ?? 0
        let streak = d?.integer(forKey: "widget_stats_streak") ?? 0
        let books = d?.integer(forKey: "widget_stats_books_year") ?? 0
        return StatsEntry(
            date: .now,
            todaySeconds: today,
            weekSeconds: week,
            streakDays: streak,
            booksThisYear: books
        )
    }
}

private func formatListeningTime(_ seconds: Int) -> String {
    if seconds <= 0 { return "0m" }
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    if hours > 0 {
        return minutes == 0 ? "\(hours)h" : "\(hours)h \(minutes)m"
    }
    return "\(minutes)m"
}

struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StatsWidgetView: View {
    let entry: StatsEntry

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                StatTile(value: formatListeningTime(entry.todaySeconds), label: "Today")
                StatTile(value: formatListeningTime(entry.weekSeconds), label: "This week")
            }
            HStack(spacing: 4) {
                StatTile(value: "\(entry.streakDays)", label: "Day streak")
                StatTile(value: "\(entry.booksThisYear)", label: "Books this year")
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct StatsWidget: Widget {
    let kind = "StatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsProvider()) { entry in
            StatsWidgetView(entry: entry)
        }
        .configurationDisplayName("Listening Stats")
        .description("Today, this week, streak, and books finished this year.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Bundle

@main
struct AbsorbWidgetBundle: WidgetBundle {
    var body: some Widget {
        AbsorbWidget()
        ArtNowPlayingWidget()
        StatsWidget()
    }
}
