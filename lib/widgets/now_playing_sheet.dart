import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/sleep_timer_service.dart';
import 'ap_episode_tile.dart';
import 'card_buttons.dart' show CardSpeedSheet;
import 'card_chapters_sheet.dart';
import 'episode_detail_sheet.dart';
import 'equalizer_sheet.dart';
import 'sleep_timer_sheet.dart';
import 'wavy_progress_indicator.dart';

// Fork addition: the player for the list layout.
//
// What plays here is long, spoken and mostly artless - channel rips and
// stream recordings - so none of the three layouts gives the cover the middle
// of the screen. The thing worth looking at is time: how much is left, when it
// ends at the speed you're listening at, and how to move around inside two
// hours of someone talking. Colours all come from the app theme, so day and
// night profiles carry through untouched.
//
//   dial   time remaining inside a progress ring
//   tape   a ruler you drag under a fixed playhead, for fine scrubbing
//   cover  the art full-bleed with a frosted control card, for when there is art
//
// Everything a podcast listener reaches for sits on the surface (speed, sleep
// timer, show notes, skip). Chapters, the equalizer and stop are in the
// overflow menu.

const _tabular = [ui.FontFeature.tabularFigures()];

void showNowPlayingSheet(BuildContext context) {
  if (!AudioPlayerService().hasBook) return;
  final cs = Theme.of(context).colorScheme;
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(),
    clipBehavior: Clip.antiAlias,
    builder: (_) => const NowPlayingSheet(),
  );
}

String _keyOf(AudioPlayerService p) {
  final id = p.currentItemId ?? '';
  final ep = p.currentEpisodeId;
  return ep == null ? id : '$id-$ep';
}

String _clockTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _speedLabel(double s) {
  final fixed = s.toStringAsFixed(2);
  final trimmed = fixed.endsWith('0') ? s.toStringAsFixed(1) : fixed;
  return '$trimmed\u00d7';
}

class NowPlayingSheet extends StatefulWidget {
  const NowPlayingSheet({super.key});

  @override
  State<NowPlayingSheet> createState() => _NowPlayingSheetState();
}

class _NowPlayingSheetState extends State<NowPlayingSheet> {
  final _player = AudioPlayerService();
  final _sleep = SleepTimerService();
  Timer? _tick;
  String _layout = 'dial';
  int _fwd = 30;
  int _back = 10;

  /// Position being previewed while the user drags, in seconds. Null when
  /// the display should follow the player.
  double? _scrub;
  DateTime? _emptySince;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _player.addListener(_onChanged);
    _sleep.addListener(_onChanged);
    _tick = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      _closeIfIdle();
      if (_scrub == null) setState(() {});
    });
    PlayerSettings.getNowPlayingLayout().then((v) {
      if (mounted && PlayerSettings.nowPlayingLayouts.contains(v)) {
        setState(() => _layout = v);
      }
    });
    PlayerSettings.getForwardSkip().then((v) {
      if (mounted) setState(() => _fwd = v);
    });
    PlayerSettings.getBackSkip().then((v) {
      if (mounted) setState(() => _back = v);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _player.removeListener(_onChanged);
    _sleep.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  /// Close once the player has had nothing loaded for a couple of seconds.
  /// Not immediately: between one queue item finishing and the next starting
  /// the player is briefly empty, and the sheet shouldn't slam shut on every
  /// episode boundary. Only pops when this sheet is the top route, so it can
  /// never take a speed or sleep sheet (or anything underneath) with it.
  void _closeIfIdle() {
    if (_player.hasBook) {
      _emptySince = null;
      return;
    }
    final since = _emptySince ??= DateTime.now();
    if (_closing) return;
    if (DateTime.now().difference(since) < const Duration(seconds: 2)) return;
    if (ModalRoute.of(context)?.isCurrent ?? false) {
      _closing = true;
      Navigator.of(context).pop();
    }
  }

  // ── Time ──

  double get _duration {
    final total = _player.totalDuration;
    if (total > 0) return total;
    return _player.duration.inMilliseconds / 1000.0;
  }

  double get _position {
    final live = _player.position.inMilliseconds / 1000.0;
    final d = _duration;
    final p = _scrub ?? live;
    if (d <= 0) return p < 0 ? 0 : p;
    return p.clamp(0.0, d).toDouble();
  }

  void _scrubTo(double seconds) {
    final d = _duration;
    setState(() {
      _scrub = d > 0 ? seconds.clamp(0.0, d).toDouble() : math.max(0.0, seconds);
    });
  }

  Future<void> _commitScrub() async {
    final target = _scrub;
    if (target == null) return;
    HapticFeedback.selectionClick();
    await _player.seekTo(Duration(milliseconds: (target * 1000).round()));
    if (mounted) setState(() => _scrub = null);
  }

  // ── Actions ──

  void _cycleLayout() {
    const all = PlayerSettings.nowPlayingLayouts;
    final next = all[(all.indexOf(_layout) + 1) % all.length];
    setState(() => _layout = next);
    PlayerSettings.setNowPlayingLayout(next);
    HapticFeedback.selectionClick();
  }

  void _openSpeed() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => CardSpeedSheet(
        player: _player,
        accent: Theme.of(context).colorScheme.primary,
        itemId: _player.currentItemId,
      ),
    );
  }

  void _openSleep() =>
      showSleepTimerSheet(context, Theme.of(context).colorScheme.primary);

  /// The cached library entry for what's playing, when it's an episode we
  /// know enough about to open its detail sheet.
  Map<String, dynamic>? _episodeEntry(LibraryProvider lib) {
    if (_player.currentEpisodeId == null) return null;
    final cached = lib.absorbingItemCache[_keyOf(_player)];
    if (cached == null) return null;
    if (cached['recentEpisode'] is! Map<String, dynamic>) return null;
    return cached;
  }

  void _openDetails(LibraryProvider lib) {
    final entry = _episodeEntry(lib);
    if (entry == null) return;
    EpisodeDetailSheet.show(
      context,
      entry,
      entry['recentEpisode'] as Map<String, dynamic>,
    );
  }

  void _openChapters() {
    showChaptersSheet(
      context: context,
      accent: Theme.of(context).colorScheme.primary,
      tt: Theme.of(context).textTheme,
      chapters: _player.chapters,
      totalDuration: _duration,
      currentPosition: _position,
      isPlaybackActive: true,
      isCastingThis: false,
      displaySpeed: _player.speed,
      player: _player,
      itemId: _player.currentItemId,
    );
  }

  void _onMenu(String value, LibraryProvider lib) {
    switch (value) {
      case 'chapters':
        _openChapters();
      case 'equalizer':
        showEqualizerSheet(
          context,
          Theme.of(context).colorScheme.primary,
          itemId: _player.currentItemId,
          itemTitle: _player.currentTitle,
        );
      case 'stop':
        // The sheet closes itself once the player reports nothing loaded.
        unawaited(_player.stop());
      default:
        if (value.startsWith('layout:')) {
          final next = value.substring(7);
          setState(() => _layout = next);
          PlayerSettings.setNowPlayingLayout(next);
        }
    }
  }

  // ── Shared pieces ──

  Widget _topBar(LibraryProvider lib, {bool onArt = false}) {
    final cs = Theme.of(context).colorScheme;
    final sleeping = _sleep.isActive;

    Widget btn(IconData icon, String tip, VoidCallback onTap,
        {bool highlight = false}) {
      final color = highlight ? cs.primary : cs.onSurface;
      return onArt
          ? IconButton.filledTonal(
              onPressed: onTap,
              tooltip: tip,
              icon: Icon(icon, color: color),
            )
          : IconButton(
              onPressed: onTap,
              tooltip: tip,
              icon: Icon(icon, color: color),
            );
    }

    final menu = PopupMenuButton<String>(
      tooltip: 'More',
      icon: Icon(Icons.more_vert_rounded, color: cs.onSurface),
      onSelected: (v) => _onMenu(v, lib),
      itemBuilder: (_) => [
        if (_player.chapters.isNotEmpty)
          const PopupMenuItem(value: 'chapters', child: Text('Chapters')),
        const PopupMenuItem(value: 'equalizer', child: Text('Equalizer')),
        const PopupMenuDivider(),
        for (final (id, label) in const [
          ('dial', 'Dial layout'),
          ('tape', 'Tape layout'),
          ('cover', 'Cover layout'),
        ])
          CheckedPopupMenuItem(
            value: 'layout:$id',
            checked: _layout == id,
            child: Text(label),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'stop', child: Text('Stop playback')),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          btn(Icons.keyboard_arrow_down_rounded, 'Close',
              () => Navigator.of(context).maybePop()),
          const Spacer(),
          btn(
            sleeping ? Icons.bedtime_rounded : Icons.bedtime_outlined,
            'Sleep timer',
            _openSleep,
            highlight: sleeping,
          ),
          btn(Icons.dashboard_customize_outlined, 'Switch layout',
              _cycleLayout),
          onArt
              ? Material(
                  color: cs.secondaryContainer,
                  shape: const CircleBorder(),
                  child: menu,
                )
              : menu,
        ],
      ),
    );
  }

  Widget _titles({TextAlign align = TextAlign.start, int titleLines = 3}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final show = _player.currentAuthor ?? '';
    final cross = align == TextAlign.center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (show.isNotEmpty)
          Text(
            show,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: tt.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          _player.currentTitle ?? '',
          maxLines: titleLines,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: tt.titleLarge?.copyWith(height: 1.2),
        ),
      ],
    );
  }

  /// Plain slider with elapsed on the left and remaining on the right.
  Widget _slider() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final d = _duration;
    final p = _position;
    final style = tt.labelMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontFeatures: _tabular,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: d > 0 ? p.clamp(0.0, d).toDouble() : 0.0,
            max: d > 0 ? d : 1.0,
            onChanged: d > 0 ? _scrubTo : null,
            onChangeEnd: d > 0 ? (_) => _commitScrub() : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(apClock(p), style: style),
              Text(apClock(d), style: style),
            ],
          ),
        ),
      ],
    );
  }

  Widget _skipButton({
    required IconData icon,
    required String tip,
    required VoidCallback onTap,
    String? label,
    double size = 34,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkResponse(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      radius: 34,
      child: Tooltip(
        message: tip,
        child: SizedBox(
          width: 56,
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: size, color: cs.onSurface),
              if (label != null)
                Text(
                  label,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontFeatures: _tabular,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Restart, back, play/pause, forward, next. The play button is a rounded
  /// square rather than a circle so it reads as the one solid object on a
  /// screen that is otherwise lines and numerals.
  Widget _transport({double playSize = 84}) {
    final cs = Theme.of(context).colorScheme;
    final playing = _player.isPlaying;
    final busy = _player.isLoadingOrBuffering;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _skipButton(
          icon: Icons.skip_previous_rounded,
          tip: 'Back to the start',
          onTap: () => _player.skipToPreviousChapter(),
        ),
        _skipButton(
          icon: Icons.fast_rewind_rounded,
          tip: 'Back $_back seconds',
          label: '$_back',
          onTap: () => _player.skipBackward(_back),
        ),
        Material(
          color: cs.onSurface,
          borderRadius: BorderRadius.circular(playSize * 0.32),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _player.togglePlayPause(fromUi: true);
            },
            child: SizedBox(
              width: playSize,
              height: playSize,
              child: Center(
                child: busy
                    ? SizedBox(
                        width: playSize * 0.34,
                        height: playSize * 0.34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: cs.surface,
                        ),
                      )
                    : Icon(
                        playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: playSize * 0.56,
                        color: cs.surface,
                      ),
              ),
            ),
          ),
        ),
        _skipButton(
          icon: Icons.fast_forward_rounded,
          tip: 'Forward $_fwd seconds',
          label: '$_fwd',
          onTap: () => _player.skipForward(_fwd),
        ),
        _skipButton(
          icon: Icons.skip_next_rounded,
          tip: 'Finish and play the next in queue',
          onTap: () => _player.skipToNextChapter(),
        ),
      ],
    );
  }

  /// Speed, sleep, show notes, queue.
  Widget _quickRow(LibraryProvider lib) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasDetails = _episodeEntry(lib) != null;
    final sleeping = _sleep.isActive;

    Widget chip({
      required Widget leading,
      required String label,
      required VoidCallback? onTap,
      bool highlight = false,
    }) {
      final fg = onTap == null
          ? cs.onSurface.withValues(alpha: 0.3)
          : (highlight ? cs.primary : cs.onSurface);
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(color: fg, size: 22),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: fg),
                    child: SizedBox(height: 24, child: Center(child: leading)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          leading: Text(
            _speedLabel(_player.speed),
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: _tabular,
            ),
          ),
          label: 'Speed',
          onTap: _openSpeed,
        ),
        chip(
          leading: sleeping
              ? Text(
                  apClock(_sleep.timeRemaining.inSeconds),
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: _tabular,
                  ),
                )
              : const Icon(Icons.bedtime_outlined),
          label: 'Sleep',
          onTap: _openSleep,
          highlight: sleeping,
        ),
        chip(
          leading: const Icon(Icons.notes_rounded),
          label: 'Show notes',
          onTap: hasDetails ? () => _openDetails(lib) : null,
        ),
        chip(
          leading: const Icon(Icons.queue_music_rounded),
          label: 'Queue',
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  /// "38 min left · ends 12:47" at the current speed.
  String _endsLine() {
    final left = (_duration - _position) / math.max(0.1, _player.speed);
    if (_duration <= 0) return '';
    final ends = DateTime.now().add(Duration(seconds: left.round()));
    return 'ends ${_clockTime(ends)}';
  }

  // ── Layout: dial ──

  Widget _dial(LibraryProvider lib) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final d = _duration;
    final p = _position;
    final fraction = d > 0 ? (p / d).clamp(0.0, 1.0).toDouble() : 0.0;
    final leftReal = (d - p) / math.max(0.1, _player.speed);

    return SafeArea(
      child: Column(
        children: [
          _topBar(lib),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: SizedBox(
              width: double.infinity,
              child: _titles(titleLines: 2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: CustomPaint(
                    painter: _DialPainter(
                      fraction: fraction,
                      track: cs.surfaceContainerHighest,
                      fill: cs.primary,
                      head: cs.onSurface,
                    ),
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 0.62,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'left at ${_speedLabel(_player.speed)}',
                                style: tt.labelLarge
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                              Text(
                                apClock(leftReal),
                                style: tt.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w300,
                                  fontFeatures: _tabular,
                                  color: cs.onSurface,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                _endsLine(),
                                style: tt.titleMedium?.copyWith(
                                  color: cs.primary,
                                  fontFeatures: _tabular,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _slider(),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _transport(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: _quickRow(lib),
          ),
        ],
      ),
    );
  }

  // ── Layout: tape ──

  Widget _tape(LibraryProvider lib) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final d = _duration;
    final p = _position;
    final fraction = d > 0 ? (p / d).clamp(0.0, 1.0).toDouble() : 0.0;
    final leftReal = (d - p) / math.max(0.1, _player.speed);

    return SafeArea(
      child: Column(
        children: [
          _topBar(lib),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        apClock(p),
                        style: tt.displayLarge?.copyWith(
                          fontSize: 84,
                          fontWeight: FontWeight.w200,
                          fontFeatures: _tabular,
                          height: 1,
                          color: _scrub != null ? cs.primary : cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d > 0
                        ? 'of ${apClock(d)}   ${apRoughDuration(leftReal)} left, ${_endsLine()}'
                        : '',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontFeatures: _tabular,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _titles(titleLines: 3),
                ],
              ),
            ),
          ),
          // The tape: ten minutes of audio per screen width, dragged under a
          // fixed playhead. A slider maps two hours onto 300 pixels, so a
          // thumb's width is half a minute; this is for finding the sentence.
          LayoutBuilder(
            builder: (context, box) {
              final pxPerSec = box.maxWidth / 600.0;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: d > 0 ? (_) => _scrubTo(p) : null,
                onHorizontalDragUpdate: d > 0
                    ? (g) => _scrubTo((_scrub ?? p) - g.delta.dx / pxPerSec)
                    : null,
                onHorizontalDragEnd: d > 0 ? (_) => _commitScrub() : null,
                onHorizontalDragCancel:
                    d > 0 ? () => setState(() => _scrub = null) : null,
                child: SizedBox(
                  height: 96,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _TapePainter(
                      position: p,
                      duration: d,
                      pxPerSec: pxPerSec,
                      played: cs.primary,
                      ahead: cs.onSurfaceVariant,
                      playhead: cs.onSurface,
                      labelStyle: (tt.labelSmall ?? const TextStyle()).copyWith(
                        color: cs.onSurfaceVariant,
                        fontFeatures: _tabular,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 3,
                backgroundColor: cs.surfaceContainerHighest,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _transport(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: _quickRow(lib),
          ),
        ],
      ),
    );
  }

  // ── Layout: cover ──

  Widget _coverBackdrop(LibraryProvider lib) {
    final cs = Theme.of(context).colorScheme;
    final show = _player.currentAuthor ?? _player.currentTitle ?? '';
    final letter =
        show.trim().isEmpty ? '' : show.trim().substring(0, 1).toUpperCase();
    final fallback = Container(
      color: cs.surfaceContainerHighest,
      alignment: const Alignment(0, -0.35),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 260,
          fontWeight: FontWeight.w800,
          height: 1,
          color: cs.onSurface.withValues(alpha: 0.08),
        ),
      ),
    );
    final url = lib.getCoverUrl(_player.currentItemId, width: 800);
    if (url == null || url.isEmpty) return fallback;
    if (url.startsWith('/')) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: lib.mediaHeaders,
      fit: BoxFit.cover,
      placeholder: (_, __) => fallback,
      errorWidget: (_, __, ___) => fallback,
    );
  }

  Widget _cover(LibraryProvider lib) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final d = _duration;
    final p = _position;
    final fraction = d > 0 ? (p / d).clamp(0.0, 1.0).toDouble() : 0.0;
    final timeStyle = tt.labelMedium?.copyWith(
      color: cs.onSurfaceVariant,
      fontFeatures: _tabular,
      fontWeight: FontWeight.w600,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        _coverBackdrop(lib),
        SafeArea(
          child: Column(
            children: [
              _topBar(lib, onArt: true),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                    child: Container(
                      color: cs.surface.withValues(alpha: 0.78),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _titles(titleLines: 2),
                          const SizedBox(height: 20),
                          // The squiggle is display-only upstream; tapping or
                          // dragging across it scrubs.
                          LayoutBuilder(
                            builder: (context, box) {
                              double at(double dx) =>
                                  (dx / box.maxWidth).clamp(0.0, 1.0).toDouble() * d;
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapUp: d > 0
                                    ? (g) {
                                        _scrubTo(at(g.localPosition.dx));
                                        _commitScrub();
                                      }
                                    : null,
                                onHorizontalDragUpdate: d > 0
                                    ? (g) => _scrubTo(at(g.localPosition.dx))
                                    : null,
                                onHorizontalDragEnd:
                                    d > 0 ? (_) => _commitScrub() : null,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: WavyProgressIndicator(
                                    value: fraction,
                                    color: cs.onSurface,
                                    trackColor:
                                        cs.onSurface.withValues(alpha: 0.2),
                                    amplitude: _player.isPlaying ? 2.5 : 0,
                                  ),
                                ),
                              );
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(apClock(p), style: timeStyle),
                              Text(_endsLine(), style: timeStyle),
                              Text('-${apClock(d - p)}', style: timeStyle),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _transport(playSize: 76),
                          const SizedBox(height: 8),
                          _quickRow(lib),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    final size = MediaQuery.sizeOf(context);
    final Widget body = switch (_layout) {
      'tape' => _tape(lib),
      'cover' => _cover(lib),
      _ => _dial(lib),
    };
    return SizedBox(
      height: size.height,
      width: size.width,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: body,
      ),
    );
  }
}

/// A 270-degree ring, open at the bottom, with a dot riding the leading edge.
class _DialPainter extends CustomPainter {
  final double fraction;
  final Color track;
  final Color fill;
  final Color head;

  _DialPainter({
    required this.fraction,
    required this.track,
    required this.fill,
    required this.head,
  });

  static const _start = math.pi * 0.75;
  static const _sweep = math.pi * 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - stroke - 4;
    if (radius <= 0) return;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawArc(rect, _start, _sweep, false, trackPaint);

    // Twelve faint ticks outside the ring: each is a twelfth of the episode,
    // which makes "about two thirds through" readable without doing sums.
    final tickPaint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..color = track;
    for (var i = 0; i <= 12; i++) {
      final a = _start + _sweep * (i / 12);
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        center + dir * (radius + 8),
        center + dir * (radius + (i % 3 == 0 ? 16 : 12)),
        tickPaint,
      );
    }

    if (fraction > 0) {
      final fillPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = fill;
      canvas.drawArc(rect, _start, _sweep * fraction, false, fillPaint);
    }

    final a = _start + _sweep * fraction;
    final at = center + Offset(math.cos(a), math.sin(a)) * radius;
    canvas.drawCircle(at, stroke * 1.25, Paint()..color = head);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.fraction != fraction ||
      old.track != track ||
      old.fill != fill ||
      old.head != head;
}

/// Ruler of the episode's timeline. The playhead is fixed at the centre; the
/// ruler slides under it. Ticks every 10 seconds, taller every minute, tallest
/// and labelled every five.
class _TapePainter extends CustomPainter {
  final double position;
  final double duration;
  final double pxPerSec;
  final Color played;
  final Color ahead;
  final Color playhead;
  final TextStyle labelStyle;

  _TapePainter({
    required this.position,
    required this.duration,
    required this.pxPerSec,
    required this.played,
    required this.ahead,
    required this.playhead,
    required this.labelStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pxPerSec <= 0) return;
    final cx = size.width / 2;
    final baseline = size.height - 22;
    final halfSpan = cx / pxPerSec;
    final end = duration > 0 ? duration : position + halfSpan;

    var first = ((position - halfSpan) / 10).floor() * 10;
    if (first < 0) first = 0;
    final last = math.min(end, position + halfSpan);

    final paint = Paint()..strokeCap = StrokeCap.round;
    for (var t = first; t <= last; t += 10) {
      final x = cx + (t - position) * pxPerSec;
      final isFive = t % 300 == 0;
      final isMinute = t % 60 == 0;
      final h = isFive ? 44.0 : (isMinute ? 26.0 : 12.0);
      final before = t <= position;
      // Fade towards the edges so the ruler reads as passing under a window.
      final edge = (1 - ((x - cx).abs() / cx)).clamp(0.0, 1.0).toDouble();
      final base = before ? played : ahead;
      paint
        ..strokeWidth = isFive ? 2.5 : 1.5
        ..color = base.withValues(
          alpha: (isMinute ? 0.95 : 0.45) * (0.25 + 0.75 * edge),
        );
      canvas.drawLine(Offset(x, baseline), Offset(x, baseline - h), paint);

      if (isFive) {
        final tp = TextPainter(
          text: TextSpan(
            text: apClock(t),
            style: labelStyle.copyWith(
              color: (labelStyle.color ?? ahead)
                  .withValues(alpha: 0.25 + 0.75 * edge),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, baseline + 6));
      }
    }

    // Playhead.
    final headPaint = Paint()
      ..color = playhead
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx, 4), Offset(cx, baseline), headPaint);
    canvas.drawCircle(Offset(cx, 4), 4, Paint()..color = playhead);
  }

  @override
  bool shouldRepaint(_TapePainter old) =>
      old.position != position ||
      old.duration != duration ||
      old.pxPerSec != pxPerSec ||
      old.played != played ||
      old.ahead != ahead ||
      old.playhead != playhead;
}

/// Docked above the nav bar on every tab while something is loaded. Tap it or
/// flick it upward for the full player.
class MiniPlayerBar extends StatefulWidget {
  /// The shell's nav-bar show/hide animation (1 = nav bar visible). When the
  /// nav bar slides away this bar becomes the bottom edge of the screen, so
  /// it grows by the system gesture inset to stay clear of the home swipe.
  final Animation<double>? navReveal;

  const MiniPlayerBar({super.key, this.navReveal});

  @override
  State<MiniPlayerBar> createState() => _MiniPlayerBarState();
}

class _MiniPlayerBarState extends State<MiniPlayerBar> {
  final _player = AudioPlayerService();
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _player.addListener(_onChanged);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _player.hasBook && _player.isPlaying) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _player.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryProvider>();
    if (!lib.queueListLayout || !_player.hasBook) {
      return const SizedBox.shrink();
    }
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final total = _player.totalDuration > 0
        ? _player.totalDuration
        : _player.duration.inMilliseconds / 1000.0;
    final pos = _player.position.inMilliseconds / 1000.0;
    final fraction =
        total > 0 ? (pos / total).clamp(0.0, 1.0).toDouble() : 0.0;
    final left = (total - pos) / math.max(0.1, _player.speed);
    final show = _player.currentAuthor ?? '';
    final sub = [
      if (show.isNotEmpty) show,
      if (total > 0) '${apRoughDuration(left)} left',
    ].join(' · ');

    return Material(
      color: cs.surfaceContainerHigh,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showNowPlayingSheet(context),
        onVerticalDragEnd: (g) {
          if ((g.primaryVelocity ?? 0) < -150) showNowPlayingSheet(context);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: fraction,
              minHeight: 2,
              backgroundColor: cs.surfaceContainerHighest,
              color: cs.primary,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  ApCover(
                    url: lib.getCoverUrl(_player.currentItemId),
                    headers: lib.mediaHeaders,
                    seed: show.isNotEmpty
                        ? show
                        : (_player.currentTitle ?? ''),
                    size: 44,
                    radius: 8,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _player.currentTitle ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleSmall,
                        ),
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontFeatures: _tabular,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: _player.isPlaying ? 'Pause' : 'Play',
                    onPressed: () => _player.togglePlayPause(fromUi: true),
                    icon: _player.isLoadingOrBuffering
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: cs.onSurface,
                            ),
                          )
                        : Icon(
                            _player.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 32,
                            color: cs.onSurface,
                          ),
                  ),
                ],
              ),
            ),
            if (widget.navReveal != null)
              AnimatedBuilder(
                animation: widget.navReveal!,
                builder: (context, _) => SizedBox(
                  height: (1 - widget.navReveal!.value) *
                      MediaQuery.viewPaddingOf(context).bottom,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
