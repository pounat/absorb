import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../services/audio_player_service.dart';
import '../services/sleep_timer_service.dart';
import 'adaptive_modal.dart';
import 'card_buttons.dart' show SimpleBookmarkSheet;
import 'sleep_timer_sheet.dart';

class DesktopNowPlayingBar extends StatefulWidget {
  final AudioPlayerService player;
  final LibraryProvider library;
  final VoidCallback onOpenNowPlaying;

  const DesktopNowPlayingBar({
    super.key,
    required this.player,
    required this.library,
    required this.onOpenNowPlaying,
  });

  @override
  State<DesktopNowPlayingBar> createState() => _DesktopNowPlayingBarState();
}

class _DesktopNowPlayingBarState extends State<DesktopNowPlayingBar> {
  int _backSkip = 10;
  int _forwardSkip = 30;
  List<double> _speedPresets = List<double>.from(
    PlayerSettings.defaultSpeedPresets,
  );
  bool _speedAdjustedTime = true;
  bool _chapterProgress = false;
  String? _lastItemId;
  String? _lastLibraryId;
  double? _dragPositionSeconds;
  double _volume = 1;
  double _volumeBeforeMute = 1;

  @override
  void initState() {
    super.initState();
    _lastItemId = widget.player.currentItemId;
    _lastLibraryId = widget.player.currentLibraryId;
    _volume = widget.player.volume.clamp(0.0, 1.0);
    if (_volume > 0) _volumeBeforeMute = _volume;
    widget.player.addListener(_onPlayerChanged);
    PlayerSettings.settingsChanged.addListener(_loadControlSettings);
    _loadControlSettings();
  }

  @override
  void didUpdateWidget(DesktopNowPlayingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.player, widget.player)) {
      oldWidget.player.removeListener(_onPlayerChanged);
      widget.player.addListener(_onPlayerChanged);
      _lastItemId = widget.player.currentItemId;
      _lastLibraryId = widget.player.currentLibraryId;
      _volume = widget.player.volume.clamp(0.0, 1.0);
      _loadControlSettings();
    }
  }

  @override
  void dispose() {
    widget.player.removeListener(_onPlayerChanged);
    PlayerSettings.settingsChanged.removeListener(_loadControlSettings);
    super.dispose();
  }

  void _onPlayerChanged() {
    if (!mounted) return;
    final itemId = widget.player.currentItemId;
    final libraryId = widget.player.currentLibraryId;
    final itemChanged = itemId != _lastItemId;
    final libraryChanged = libraryId != _lastLibraryId;
    _lastItemId = itemId;
    _lastLibraryId = libraryId;
    if (itemChanged) _dragPositionSeconds = null;
    if (libraryChanged) _loadControlSettings();
    setState(() {});
  }

  Future<void> _loadControlSettings() async {
    final libraryId = widget.player.currentLibraryId;
    final results = await Future.wait<Object>([
      PlayerSettings.getEffectiveBackSkip(libraryId: libraryId),
      PlayerSettings.getEffectiveForwardSkip(libraryId: libraryId),
      PlayerSettings.getSpeedPresets(),
      PlayerSettings.getSpeedAdjustedTime(),
      PlayerSettings.getNotificationChapterProgress(),
    ]);
    if (!mounted) return;
    setState(() {
      _backSkip = results[0] as int;
      _forwardSkip = results[1] as int;
      _speedPresets = results[2] as List<double>;
      _speedAdjustedTime = results[3] as bool;
      _chapterProgress = results[4] as bool;
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    if (!player.hasBook) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final title = player.currentTitle?.trim();
    final author = player.currentAuthor?.trim();
    final displayTitle = title == null || title.isEmpty
        ? 'Unknown title'
        : title;
    final displayAuthor = author == null || author.isEmpty
        ? 'Unknown author'
        : author;
    final totalSeconds = _safeTotalSeconds(player.totalDuration);
    final hasChapters = player.chapters.isNotEmpty;
    final chapterTitle = player.currentChapter?['title'] as String?;

    return Material(
      color: cs.surfaceContainerLow,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
        ),
        child: SizedBox(
          height: 94,
          child: Column(
            children: [
              SizedBox(
                height: 28,
                child: StreamBuilder<Duration>(
                  stream: player.absolutePositionStream,
                  initialData: player.position,
                  builder: (context, snapshot) {
                    final streamSeconds =
                        (snapshot.data ?? player.position).inMilliseconds /
                        1000.0;
                    final positionSeconds = _effectivePosition(
                      streamSeconds,
                      totalSeconds,
                    );
                    final progressWindow = _DesktopProgressWindow.fromChapter(
                      totalSeconds: totalSeconds,
                      chapter: _chapterProgress ? player.currentChapter : null,
                    );
                    final rangePosition = progressWindow.relativePosition(
                      positionSeconds,
                    );
                    double absolutePosition(double value) =>
                        progressWindow.absolutePosition(value);
                    return _PositionControl(
                      positionSeconds: rangePosition,
                      totalSeconds: progressWindow.durationSeconds,
                      displaySpeed: _speedAdjustedTime ? player.speed : 1.0,
                      enabled: progressWindow.durationSeconds > 0,
                      accent: cs.primary,
                      onChangeStart: (value) {
                        setState(
                          () => _dragPositionSeconds = absolutePosition(value),
                        );
                      },
                      onChanged: (value) {
                        setState(
                          () => _dragPositionSeconds = absolutePosition(value),
                        );
                      },
                      onChangeEnd: (value) async {
                        final seekSeconds = absolutePosition(value);
                        setState(() => _dragPositionSeconds = seekSeconds);
                        await player.seekTo(
                          Duration(milliseconds: (seekSeconds * 1000).round()),
                        );
                        if (mounted) {
                          setState(() => _dragPositionSeconds = null);
                        }
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: _NowPlayingIdentity(
                          coverUrl: _coverUrl(),
                          mediaHeaders: widget.library.mediaHeaders,
                          title: displayTitle,
                          author: displayAuthor,
                          chapter: chapterTitle,
                          onTap: widget.onOpenNowPlaying,
                        ),
                      ),
                      const SizedBox(width: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 210),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasChapters)
                              Tooltip(
                                message: l.previousChapterTooltip,
                                child: IconButton(
                                  onPressed: player.hasActiveSession
                                      ? player.skipToPreviousChapter
                                      : null,
                                  icon: const Icon(Icons.skip_previous_rounded),
                                ),
                              ),
                            _SkipButton(
                              seconds: _backSkip,
                              forward: false,
                              onPressed: player.hasActiveSession
                                  ? () => player.skipBackward(_backSkip)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Tooltip(
                              message: player.isPlaying ? 'Pause' : 'Play',
                              child: IconButton.filled(
                                onPressed:
                                    player.isLoadingOrBuffering &&
                                        !player.isPlaying
                                    ? null
                                    : player.togglePlayPause,
                                icon:
                                    player.isLoadingOrBuffering &&
                                        !player.isPlaying
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: cs.onPrimary,
                                        ),
                                      )
                                    : Icon(
                                        player.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                      ),
                                iconSize: 27,
                                style: IconButton.styleFrom(
                                  minimumSize: const Size.square(46),
                                  maximumSize: const Size.square(46),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _SkipButton(
                              seconds: _forwardSkip,
                              forward: true,
                              onPressed: player.hasActiveSession
                                  ? () => player.skipForward(_forwardSkip)
                                  : null,
                            ),
                            if (hasChapters)
                              Tooltip(
                                message: l.nextChapterTooltip,
                                child: IconButton(
                                  onPressed: player.hasActiveSession
                                      ? player.skipToNextChapter
                                      : null,
                                  icon: const Icon(Icons.skip_next_rounded),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 3,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Tooltip(
                              message: l.bookmarks,
                              child: IconButton(
                                onPressed: player.currentItemId == null
                                    ? null
                                    : _openBookmarks,
                                icon: Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 20,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            _SleepTimerButton(
                              onPressed: () =>
                                  showSleepTimerSheet(context, cs.primary),
                            ),
                            const SizedBox(width: 8),
                            _SpeedControl(
                              speed: player.speed,
                              presets: _speedPresets,
                              onSelected: player.setSpeed,
                            ),
                            const SizedBox(width: 12),
                            Tooltip(
                              message: _volume <= 0 ? 'Unmute' : 'Mute',
                              child: IconButton(
                                onPressed: _toggleMute,
                                icon: Icon(
                                  _volumeIcon,
                                  size: 20,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Flexible(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 72,
                                  maxWidth: 130,
                                ),
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 5,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12,
                                    ),
                                  ),
                                  child: Slider(
                                    value: _volume,
                                    onChanged: _setVolume,
                                    semanticFormatterCallback: (value) =>
                                        'Volume ${(value * 100).round()} percent',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openBookmarks() {
    final itemId = widget.player.currentItemId;
    if (itemId == null) return;
    final accent = Theme.of(context).colorScheme.primary;
    showAdaptiveSheetDialog(
      context: context,
      widthClass: DialogWidthClass.action,
      initialChildSize: 0.6,
      minChildSize: 0.05,
      maxChildSize: 0.9,
      snap: true,
      backgroundColor: Colors.transparent,
      builder: (ctx, sc) => SimpleBookmarkSheet(
        itemId: itemId,
        player: widget.player,
        accent: accent,
        scrollController: sc,
        onChanged: () {},
      ),
    );
  }

  String? _coverUrl() {
    final itemId = widget.player.currentItemId;
    final providerUrl = widget.library.getCoverUrl(itemId, width: 160);
    if (providerUrl != null && providerUrl.isNotEmpty) return providerUrl;
    final playerUrl = widget.player.currentCoverUrl;
    return playerUrl == null || playerUrl.isEmpty ? null : playerUrl;
  }

  double _effectivePosition(double streamSeconds, double totalSeconds) {
    final raw = _dragPositionSeconds ?? streamSeconds;
    if (!raw.isFinite || raw <= 0 || totalSeconds <= 0) return 0;
    return raw.clamp(0.0, totalSeconds).toDouble();
  }

  static double _safeTotalSeconds(double value) {
    if (!value.isFinite || value <= 0) return 0;
    return value;
  }

  IconData get _volumeIcon {
    if (_volume <= 0) return Icons.volume_off_rounded;
    if (_volume < 0.5) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  void _setVolume(double value) {
    setState(() {
      _volume = value;
      if (value > 0) _volumeBeforeMute = value;
    });
    unawaited(widget.player.setVolume(value));
  }

  void _toggleMute() {
    _setVolume(_volume <= 0 ? _volumeBeforeMute : 0);
  }
}

class _DesktopProgressWindow {
  final double startSeconds;
  final double durationSeconds;

  const _DesktopProgressWindow({
    required this.startSeconds,
    required this.durationSeconds,
  });

  factory _DesktopProgressWindow.fromChapter({
    required double totalSeconds,
    required Map<String, dynamic>? chapter,
  }) {
    if (totalSeconds <= 0 || chapter == null) {
      return _DesktopProgressWindow(
        startSeconds: 0,
        durationSeconds: totalSeconds,
      );
    }

    final rawStart = (chapter['start'] as num?)?.toDouble() ?? 0;
    final rawEnd = (chapter['end'] as num?)?.toDouble() ?? totalSeconds;
    if (!rawStart.isFinite || !rawEnd.isFinite || rawEnd <= rawStart) {
      return _DesktopProgressWindow(
        startSeconds: 0,
        durationSeconds: totalSeconds,
      );
    }

    final start = rawStart.clamp(0.0, totalSeconds).toDouble();
    final end = rawEnd.clamp(start, totalSeconds).toDouble();
    if (end <= start) {
      return _DesktopProgressWindow(
        startSeconds: 0,
        durationSeconds: totalSeconds,
      );
    }
    return _DesktopProgressWindow(
      startSeconds: start,
      durationSeconds: end - start,
    );
  }

  double relativePosition(double absoluteSeconds) =>
      (absoluteSeconds - startSeconds).clamp(0.0, durationSeconds).toDouble();

  double absolutePosition(double relativeSeconds) =>
      startSeconds + relativeSeconds.clamp(0.0, durationSeconds).toDouble();
}

class _PositionControl extends StatelessWidget {
  final double positionSeconds;
  final double totalSeconds;
  final double displaySpeed;
  final bool enabled;
  final Color accent;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _PositionControl({
    required this.positionSeconds,
    required this.totalSeconds,
    required this.displaySpeed,
    required this.enabled,
    required this.accent,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final max = enabled ? totalSeconds : 1.0;
    final value = enabled ? positionSeconds.clamp(0.0, max).toDouble() : 0.0;
    final remaining = enabled ? totalSeconds - value : 0.0;
    final speed = displaySpeed.isFinite && displaySpeed > 0
        ? displaySpeed
        : 1.0;
    final displayValue = value / speed;
    final displayRemaining = remaining / speed;
    final displayTotal = totalSeconds / speed;
    final timeStyle = tt.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontSize: 10,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Row(
      children: [
        const SizedBox(width: 12),
        SizedBox(
          width: 50,
          child: Text(
            _formatTime(displayValue),
            key: const ValueKey('desktop-now-playing-elapsed'),
            textAlign: TextAlign.right,
            style: timeStyle,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              inactiveTrackColor: cs.onSurface.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbColor: accent,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value,
              max: max,
              onChangeStart: enabled ? onChangeStart : null,
              onChanged: enabled ? onChanged : null,
              onChangeEnd: enabled ? onChangeEnd : null,
              semanticFormatterCallback: (value) =>
                  '${_formatTime(value / speed)} of ${_formatTime(displayTotal)}',
            ),
          ),
        ),
        SizedBox(
          width: 50,
          child: Text(
            '-${_formatTime(displayRemaining)}',
            key: const ValueKey('desktop-now-playing-remaining'),
            style: timeStyle,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _NowPlayingIdentity extends StatelessWidget {
  final String? coverUrl;
  final Map<String, String> mediaHeaders;
  final String title;
  final String author;
  final String? chapter;
  final VoidCallback onTap;

  const _NowPlayingIdentity({
    required this.coverUrl,
    required this.mediaHeaders,
    required this.title,
    required this.author,
    this.chapter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final subtitle = chapter == null || chapter!.isEmpty
        ? author
        : '$author · $chapter';
    final placeholder = ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.auto_stories_rounded,
        color: cs.onSurfaceVariant.withValues(alpha: 0.55),
      ),
    );

    return Semantics(
      button: true,
      label: '${l.openNowPlayingTooltip}: $title',
      child: Tooltip(
        message: l.openNowPlayingTooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox.square(
                    dimension: 54,
                    child: coverUrl == null
                        ? placeholder
                        : CachedNetworkImage(
                            imageUrl: coverUrl!,
                            httpHeaders: mediaHeaders,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => placeholder,
                            errorWidget: (_, __, ___) => placeholder,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  final int seconds;
  final bool forward;
  final VoidCallback? onPressed;

  const _SkipButton({
    required this.seconds,
    required this.forward,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final direction = forward ? 'forward' : 'back';
    return Tooltip(
      message: 'Skip $direction $seconds seconds',
      child: IconButton(onPressed: onPressed, icon: _icon(context)),
    );
  }

  Widget _icon(BuildContext context) {
    final color = onPressed == null
        ? Theme.of(context).disabledColor
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final builtIn = switch ((seconds, forward)) {
      (5, true) => Icons.forward_5_rounded,
      (10, true) => Icons.forward_10_rounded,
      (30, true) => Icons.forward_30_rounded,
      (5, false) => Icons.replay_5_rounded,
      (10, false) => Icons.replay_10_rounded,
      (30, false) => Icons.replay_30_rounded,
      _ => null,
    };
    if (builtIn != null) return Icon(builtIn, color: color);
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          forward ? Icons.rotate_right_rounded : Icons.rotate_left_rounded,
          color: color,
        ),
        Text(
          '$seconds',
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _SpeedControl extends StatelessWidget {
  final double speed;
  final List<double> presets;
  final ValueChanged<double> onSelected;

  const _SpeedControl({
    required this.speed,
    required this.presets,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = '${_formatSpeed(speed)}x';
    return Semantics(
      button: true,
      label: 'Playback speed, $label',
      child: PopupMenuButton<double>(
        tooltip: 'Playback speed',
        onSelected: onSelected,
        itemBuilder: (context) => [
          for (final preset in presets)
            PopupMenuItem<double>(
              value: preset,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_formatSpeed(preset)}x'),
                  if ((preset - speed).abs() < 0.001)
                    Icon(Icons.check_rounded, size: 18, color: cs.primary),
                ],
              ),
            ),
        ],
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SleepTimerButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SleepTimerButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final service = SleepTimerService();
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final active = service.isActive;
        return Tooltip(
          message: l.sleepTimer,
          child: active
              ? TextButton.icon(
                  onPressed: onPressed,
                  icon: Icon(Icons.bedtime_rounded, size: 18, color: cs.primary),
                  label: Text(
                    service.displayLabel,
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : IconButton(
                  onPressed: onPressed,
                  icon: Icon(
                    Icons.bedtime_outlined,
                    size: 20,
                    color: cs.onSurfaceVariant,
                  ),
                ),
        );
      },
    );
  }
}

String _formatTime(double seconds) {
  final duration = Duration(seconds: seconds.isFinite ? seconds.round() : 0);
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  if (hours > 0) return '$hours:$minutes:$secs';
  return '${duration.inMinutes}:$secs';
}

String _formatSpeed(double speed) {
  final fixed = speed.toStringAsFixed(2);
  return fixed
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}
