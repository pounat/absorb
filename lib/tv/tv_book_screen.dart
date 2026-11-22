import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/ebook_cache.dart';
import '../services/narrated_books.dart';
import '../services/narration_service.dart';
import '../widgets/ebook_router.dart';
import 'tv_cover_tile.dart';
import 'tv_browse.dart';
import 'tv_focusable.dart';
import 'tv_now_playing_bar.dart';
import 'tv_home_screen.dart' show TvPlayRequest, tvPlayerRequest;
import 'tv_playback.dart' show tvCoverColor;

void openTvBook(BuildContext context, Map<String, dynamic> item) {
  final id = item['id'] as String?;
  if (id == null) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => TvBookScreen(itemId: id, preview: item),
    ),
  );
}

/// A book's page on the TV: cover, details and Play, which grows into the
/// full player. A podcast lists its episodes instead.
class TvBookScreen extends StatefulWidget {
  final String itemId;
  final Map<String, dynamic> preview;

  const TvBookScreen({super.key, required this.itemId, required this.preview});

  @override
  State<TvBookScreen> createState() => _TvBookScreenState();
}

class _TvBookScreenState extends State<TvBookScreen> {
  final _playKey = GlobalKey();
  final _restartKey = GlobalKey();
  Map<String, dynamic>? _item;

  Map<String, dynamic> get _shown => _item ?? widget.preview;
  Map<String, dynamic> get _media => (_shown['media'] as Map?)?.cast<String, dynamic>() ?? const {};
  Map<String, dynamic> get _meta => (_media['metadata'] as Map?)?.cast<String, dynamic>() ?? const {};
  bool get _isPodcast => _shown['mediaType'] == 'podcast';

  /// The first series the book is in, for "More in series".
  Map<String, dynamic>? get _series {
    final series = _meta['series'];
    if (series is List && series.isNotEmpty && series.first is Map) {
      final s = (series.first as Map).cast<String, dynamic>();
      return s['id'] == null ? null : s;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
    // Learn the cover's color now, for the player's backdrop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) tvCoverColor(context, widget.itemId, onFound: () {});
    });
  }

  Future<void> _load() async {
    final api = context.read<AuthProvider>().apiService;
    final full = await api?.getLibraryItem(widget.itemId);
    if (mounted && full != null) {
      setState(() => _item = full);
      unawaited(_lookForNarration(full));
    }
  }

  bool _lookingForNarration = false;

  /// As on the phone: an Audiobookshelf EPUB with no audio files may read
  /// itself aloud, and then it plays like an audiobook.
  Future<void> _lookForNarration(Map<String, dynamic> item) async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null || auth.isBookOrbit || !PlayerSettings.isEbookOnly(item, countNarration: false)) return;
    final file = resolveEbookFile(item);
    if (file == null || ebookExtFromFile(file) != '.epub' || NarratedBooks.checked(widget.itemId)) return;
    setState(() => _lookingForNarration = true);
    try {
      final o = await NarrationService.instance.probe(api, item, onNarrated: (duration) {
        if (duration == null || duration <= 0) return;
        unawaited(NarratedBooks.set(widget.itemId, duration).then((_) {
          if (mounted) setState(() => _lookingForNarration = false);
        }));
      });
      if (o != null) {
        await NarrationService.instance.markAudiobook(widget.itemId, o);
      } else if (await NarrationService.instance.knownNarrated(widget.itemId) == false) {
        await NarratedBooks.set(widget.itemId, null);
      }
    } catch (e) {
      debugPrint('[TvBook] looking for narration failed: $e');
    }
    if (mounted) setState(() => _lookingForNarration = false);
  }

  Map<String, dynamic>? get _ebookFile => _item == null ? null : resolveEbookFile(_item);

  // Only the EPUB reader works with a remote; PDF, comic and Kindle files are touch only.
  bool get _epub {
    final file = _ebookFile;
    return file != null && ebookExtFromFile(file) == '.epub';
  }

  bool get _narrated => NarratedBooks.contains(widget.itemId) || _media['narration'] != null;

  Future<void> _read({bool along = false}) async {
    var file = _ebookFile;
    file ??= await cachedEbookFileFor(widget.itemId);
    if (!mounted || file == null) return;
    openEbookReader(
      context,
      itemId: widget.itemId,
      title: tvItemNames(_shown).title,
      ebookFile: file,
      startReadAlong: along,
    );
  }

  bool get _hasAudio {
    // Until the full item is in, assume it plays rather than flash "No audio".
    if (_isPodcast || _item == null || _lookingForNarration || _narrated) return true;
    final tracks = _media['tracks'] as List?;
    final files = _media['audioFiles'] as List?;
    final duration = (_media['duration'] as num?)?.toDouble() ?? 0;
    return (tracks?.isNotEmpty ?? false) || (files?.isNotEmpty ?? false) || duration > 0;
  }

  /// Starts the book, or an episode, and grows the pressed button into the
  /// full player while it loads.
  /// Play: back Home, where the player opens on this book and starts it.
  void _play(GlobalKey from, {Map<String, dynamic>? episode, bool fromStart = false}) {
    final item = _shown;
    Navigator.of(context).popUntil((r) => r.isFirst);
    tvPlayerRequest.value = TvPlayRequest(item, episode: episode, fromStart: fromStart);
  }

  /// A description as plain text: paragraphs and breaks kept as line
  /// breaks, so they don't run together, and the usual entities decoded.
  static String _plainText(String html) => html
      .replaceAll(RegExp(r'<br\s*/?>|</(p|div|li|h\d)>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();

  String _hm(AppLocalizations l, double seconds) {
    final d = Duration(seconds: seconds.round());
    return l.episodeDetailDurationHm(d.inHours, d.inMinutes % 60);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final lib = context.watch<LibraryProvider>();
    final names = tvItemNames(_shown);
    final narrator = _meta['narratorName'] as String? ?? '';
    final series = _meta['seriesName'] as String? ?? '';
    final description = _plainText(_meta['description'] as String? ?? '');
    final duration = (_media['duration'] as num?)?.toDouble() ?? 0;
    final progress = lib.getProgressData(widget.itemId);
    final pct = (progress?['progress'] as num?)?.toDouble() ?? 0;
    final started = !_isPodcast && pct > 0 && progress?['isFinished'] != true;
    final episodes = _isPodcast
        ? ((_media['episodes'] as List?) ?? const []).whereType<Map<String, dynamic>>().toList()
        : <Map<String, dynamic>>[];
    episodes.sort((a, b) => ((b['publishedAt'] as num?) ?? 0).compareTo((a['publishedAt'] as num?) ?? 0));

    final finished = progress?['isFinished'] == true;
    final genres = ((_meta['genres'] as List?) ?? const []).whereType<String>().take(3).join(', ');
    final details = <String>[
      if (narrator.isNotEmpty) l.tvNarratedBy(narrator),
      if (series.isNotEmpty) series,
      if (duration > 0) _hm(l, duration),
    ];
    final status = finished
        ? l.tvFinished
        : started && duration > 0
            ? l.tvTimeLeft(_hm(l, duration * (1 - pct)))
            : null;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(64, 48, 64, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 340,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: TvCover(itemId: widget.itemId, title: names.title, author: names.author, width: 700),
                    ),
                  ),
                ),
                const SizedBox(width: 56),
                Expanded(
                  child: ListView(
                    clipBehavior: Clip.none,
                    padding: const EdgeInsets.only(bottom: 48),
                    children: [
                      Text(names.title, style: tt.displaySmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(names.author, style: tt.titleLarge?.copyWith(color: cs.onSurfaceVariant)),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(details.join('  ·  '), style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                      if (genres.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(genres, style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                      if (status != null) ...[
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            if (started) ...[
                              SizedBox(
                                width: 280,
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 14),
                            ],
                            Text(status, style: tt.titleSmall?.copyWith(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 28),
                      if (!_isPodcast)
                        // Wraps to a second line rather than running off the screen.
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            KeyedSubtree(
                              key: _playKey,
                              child: TvPillButton(
                                autofocus: true,
                                selected: true,
                                icon: Icons.play_arrow_rounded,
                                label: _hasAudio ? (started ? l.tvContinue : l.tvPlay) : l.tvNoAudio,
                                onSelect: _hasAudio ? () => _play(_playKey) : null,
                              ),
                            ),
                            if (_hasAudio && (started || finished)) ...[
                              KeyedSubtree(
                                key: _restartKey,
                                child: TvPillButton(
                                  icon: Icons.replay_rounded,
                                  label: l.tvStartOver,
                                  onSelect: () => _play(_restartKey, fromStart: true),
                                ),
                              ),
                            ],
                            if (_epub && _narrated && !_lookingForNarration) ...[
                              TvPillButton(
                                icon: Icons.auto_stories_rounded,
                                label: l.readAlong,
                                onSelect: () => _read(along: true),
                              ),
                            ],
                            if (_epub) ...[
                              TvPillButton(
                                icon: Icons.menu_book_rounded,
                                label: l.tvRead,
                                onSelect: _read,
                              ),
                            ],
                            if (_series != null) ...[
                              TvPillButton(
                                icon: Icons.collections_bookmark_rounded,
                                label: l.tvMoreInSeries,
                                onSelect: () => TvBooksPage.open(
                                  context,
                                  _series!['name'] as String? ?? '',
                                  (c) => tvSeriesBooks(c, _series!['id'] as String? ?? '', libraryId: _shown['libraryId'] as String?),
                                ),
                              ),
                            ],
                          ],
                        ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 28),
                        _TvScrollText(text: description, maxHeight: _isPodcast ? 120 : 300),
                      ],
                      if (_isPodcast) ...[
                        const SizedBox(height: 24),
                        for (var i = 0; i < episodes.length; i++)
                          _EpisodeRow(
                            episode: episodes[i],
                            autofocus: i == 0,
                            progress: lib.getProgressData('${widget.itemId}-${episodes[i]['id']}'),
                            durationLabel: _hm(l, (episodes[i]['duration'] as num?)?.toDouble() ?? 0),
                            onPlay: (key) => _play(key, episode: episodes[i]),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(right: 28, bottom: 24, child: TvNowPlayingBar(hint: l.tvNowPlayingHint)),
        ],
      ),
    );
  }
}

/// A description the remote can read through: it takes focus like
/// anything else, then up and down scroll it, and past either end focus
/// moves on.
class _TvScrollText extends StatefulWidget {
  final String text;
  final double maxHeight;

  const _TvScrollText({required this.text, required this.maxHeight});

  @override
  State<_TvScrollText> createState() => _TvScrollTextState();
}

class _TvScrollTextState extends State<_TvScrollText> {
  final _scroll = ScrollController();
  bool _focused = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is KeyUpEvent || !_scroll.hasClients) return KeyEventResult.ignored;
    final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
    final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
    if (!down && !up) return KeyEventResult.ignored;
    final pos = _scroll.position;
    if (down && pos.pixels >= pos.maxScrollExtent - 1) return KeyEventResult.ignored;
    if (up && pos.pixels <= pos.minScrollExtent + 1) return KeyEventResult.ignored;
    final step = widget.maxHeight * 0.6;
    _scroll.animateTo(
      (pos.pixels + (down ? step : -step)).clamp(pos.minScrollExtent, pos.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Focus(
      onKeyEvent: _onKey,
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _focused ? cs.surfaceContainerHigh : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _focused ? cs.onSurface : Colors.transparent, width: 2),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          child: SingleChildScrollView(
            controller: _scroll,
            physics: const NeverScrollableScrollPhysics(),
            child: Text(widget.text, style: tt.bodyLarge?.copyWith(height: 1.45)),
          ),
        ),
      ),
    );
  }
}

class _EpisodeRow extends StatefulWidget {
  final Map<String, dynamic> episode;
  final Map<String, dynamic>? progress;
  final String durationLabel;
  final bool autofocus;
  final void Function(GlobalKey from) onPlay;

  const _EpisodeRow({
    required this.episode,
    required this.progress,
    required this.durationLabel,
    required this.autofocus,
    required this.onPlay,
  });

  @override
  State<_EpisodeRow> createState() => _EpisodeRowState();
}

class _EpisodeRowState extends State<_EpisodeRow> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final finished = widget.progress?['isFinished'] == true;
    final pct = (widget.progress?['progress'] as num?)?.toDouble() ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TvFocusable(
        key: _key,
        autofocus: widget.autofocus,
        focusScale: 1.02,
        onSelect: () => widget.onPlay(_key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Icon(finished ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded, color: cs.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.episode['title'] as String? ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleMedium,
                ),
              ),
              if (!finished && pct > 0) ...[
                SizedBox(width: 80, child: LinearProgressIndicator(value: pct)),
                const SizedBox(width: 16),
              ],
              Text(widget.durationLabel, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
