import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/ebook_cache.dart';
import '../services/narrated_books.dart';
import '../widgets/absorb_wave_icon.dart';
import '../widgets/card_buttons.dart';
import '../widgets/card_playback_controls.dart';
import '../widgets/card_progress_bar.dart';
import '../widgets/card_chapters_sheet.dart';
import '../widgets/ebook_router.dart';
import '../widgets/expressive.dart';
import '../widgets/overlay_toast.dart';
import 'tv_book_screen.dart';
import 'tv_home_screen.dart' show tvPlayerClose;
import 'tv_cover_tile.dart';
import 'tv_night_mode.dart';
import 'tv_playback.dart';

/// The TV's own player: the book's details and controls, made for a remote,
/// beside the big cover the home row grows. Light to build, so it can slide
/// in on even a slow TV. The pills open the same sheets as the phone.
class TvPlayerPanel extends StatefulWidget {
  final Map<String, dynamic> item;

  const TvPlayerPanel({super.key, required this.item});

  @override
  State<TvPlayerPanel> createState() => _TvPlayerPanelState();
}

class _TvPlayerPanelState extends State<TvPlayerPanel> {
  final _player = AudioPlayerService();
  final _playFocus = FocusNode(debugLabel: 'tv player play');
  Timer? _tick;
  Map<String, dynamic>? _full;

  String get _itemId => widget.item['id'] as String? ?? '';
  Map<String, dynamic>? get _episode => tvEpisodeOf(widget.item);
  String? get _episodeId => _episode?['id'] as String?;
  String get _key => _episodeId == null ? _itemId : '$_itemId-$_episodeId';

  bool get _active =>
      _player.hasBook && _player.currentItemId == _itemId && _player.currentEpisodeId == _episodeId;

  Map<String, dynamic> get _media => ((_full ?? widget.item)['media'] as Map?)?.cast<String, dynamic>() ?? const {};

  @override
  void initState() {
    super.initState();
    _player.addListener(_changed);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _changed());
    _loadFull();
    // The remote starts on play when the player opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _player.removeListener(_changed);
    _playFocus.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  // The shelf entry is lean; the full item says whether there's an ebook.
  Future<void> _loadFull() async {
    final api = context.read<AuthProvider>().apiService;
    final full = await api?.getLibraryItem(_itemId);
    if (mounted && full != null) setState(() => _full = full);
  }

  Map<String, dynamic>? get _ebookFile => _media['ebookFile'] as Map<String, dynamic>?;

  // Only the EPUB reader works with a remote; PDF, comic and Kindle files are touch only.
  bool get _epub {
    final file = _ebookFile;
    return file != null && ebookExtFromFile(file) == '.epub';
  }
  bool get _narrated => _episodeId == null && (NarratedBooks.contains(_itemId) || _media['narration'] != null);

  Color get _accent => Theme.of(context).colorScheme.primary;

  bool _starting = false;

  /// Silent and closed at once; the spot saves to the server meanwhile,
  /// which can take a few seconds.
  void _stop() {
    unawaited(_player.pause());
    tvPlayerClose.value++;
    unawaited(_player.stop());
  }

  void _play() {
    if (_active) {
      _player.togglePlayPause(fromUi: true);
    } else {
      setState(() => _starting = true);
      startTvPlayback(context, _full ?? widget.item, episode: _episode);
    }
  }

  /// The chapter list. Before the book is loaded it's the book's own list,
  /// and picking one asks to play from there.
  void _chapters() {
    final active = _active;
    final total = (_media['duration'] as num?)?.toDouble() ?? 0;
    showChaptersSheet(
      context: context,
      accent: _accent,
      tt: Theme.of(context).textTheme,
      chapters: active ? _player.chapters : ((_media['chapters'] as List?) ?? const []),
      totalDuration: active ? _player.totalDuration : total,
      currentPosition: active ? _player.position.inMilliseconds / 1000 : 0,
      isPlaybackActive: active,
      isCastingThis: false,
      displaySpeed: _player.speed,
      player: _player,
      itemId: _itemId,
    );
  }

  Future<void> _read({bool along = false}) async {
    var file = _ebookFile;
    file ??= await cachedEbookFileFor(_itemId);
    if (!mounted) return;
    if (file == null) {
      showOverlayToast(context, AppLocalizations.of(context)!.noEbookFileFound, icon: Icons.menu_book_outlined);
      return;
    }
    openEbookReader(
      context,
      itemId: _itemId,
      title: tvItemNames(_full ?? widget.item).title,
      ebookFile: file,
      startReadAlong: along,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final names = tvItemNames(_full ?? widget.item);
    final lib = context.watch<LibraryProvider>();
    final accent = cs.primary;

    final active = _active;
    if (active) _starting = false;
    final total = active ? _player.totalDuration : (_media['duration'] as num?)?.toDouble() ?? 0;
    final saved = lib.getProgressData(_key);
    final pct = (saved?['progress'] as num?)?.toDouble() ?? 0;
    final chapters = active ? _player.chapters : ((_media['chapters'] as List?) ?? const []);
    final pos = active ? _player.position.inMilliseconds / 1000 : pct * total;
    var chapterIdx = 0;
    for (var i = 0; i < chapters.length; i++) {
      final ch = chapters[i] as Map;
      final start = (ch['start'] as num?)?.toDouble() ?? 0;
      final end = (ch['end'] as num?)?.toDouble() ?? total;
      if (pos >= start && pos < end) {
        chapterIdx = i;
        break;
      }
    }
    final chapterName = chapters.isEmpty ? null : (chapters[chapterIdx] as Map)['title'] as String?;
    final playing = active && _player.isPlaying;
    final title = _episode?['title'] as String? ?? names.title;
    final subtitle = _episode != null ? names.title : names.author;
    final libraryId = widget.item['libraryId'] as String?;

    // The card's own buttons, two to a row as on the phone.
    Widget wide(IconData icon, String label, VoidCallback onTap) => CardWideButton(
          icon: icon,
          label: label,
          accent: accent,
          isActive: true,
          alwaysEnabled: true,
          onTap: onTap,
        );
    // All of them whether the book is loaded yet or not.
    final buttons = <Widget>[
      CardSpeedButtonInline(player: _player, accent: accent, isActive: true, itemId: _itemId, libraryId: libraryId),
      CardSleepButtonInline(accent: accent, isActive: true),
      if (chapters.isNotEmpty) wide(Icons.list_rounded, l.chapters, _chapters),
      CardBookmarkButtonInline(player: _player, accent: accent, isActive: active, itemId: _itemId, episodeId: _episodeId),
      wide(Icons.bedtime_rounded, l.tvNightMode, TvNightMode.start),
      if (_epub && _narrated) wide(Icons.auto_stories_rounded, l.readAlong, () => _read(along: true)),
      if (_epub) wide(Icons.menu_book_rounded, l.tvRead, _read),
      // A podcast's page is the show with its episodes.
      wide(Icons.info_outline_rounded, _episodeId != null ? l.tvPodcastDetails : l.bookDetailsLabel,
          () => openTvBook(context, _full ?? widget.item)),
      if (active) wide(Icons.stop_rounded, l.tvStop, _stop),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The wave sits beside the title, so nothing moves when it shows.
        Row(children: [
          Flexible(
            child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          AnimatedOpacity(
            opacity: playing ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: AbsorbWaveIcon(size: 26, color: accent),
          ),
        ]),
        const SizedBox(height: 4),
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 20),
        CardDualProgressBar(
          player: _player,
          accent: accent,
          isActive: active,
          staticProgress: pct,
          staticDuration: total,
          chapters: chapters,
          showBookBar: true,
          showChapterBar: chapters.isNotEmpty,
          chapterName: chapterName,
          chapterIndex: chapterIdx,
          totalChapters: chapters.length,
          itemId: _itemId,
          libraryId: libraryId,
        ),
        const SizedBox(height: 18),
        CardPlaybackControls(
          player: _player,
          accent: accent,
          isActive: active,
          isStarting: _starting,
          onStart: _play,
          itemId: _itemId,
          showPlayButton: true,
          playButtonSize: 76,
          libraryId: libraryId,
          playFocusNode: _playFocus,
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < buttons.length; i += 3)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: buttons.length - i > 1
                ? ExpressiveButtonRow(widen: true, children: buttons.sublist(i, (i + 3).clamp(0, buttons.length)))
                : Row(children: [Expanded(child: buttons[i])]),
          ),
      ],
    );
  }
}
