import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../screens/app_shell.dart';
import '../screens/car_mode_screen.dart';
import '../services/audio_player_service.dart';
import '../services/bookmark_service.dart';
import '../services/chromecast_service.dart';
import '../services/download_service.dart';
import '../services/equalizer_service.dart';
import '../services/playback_history_service.dart';
import '../services/scoped_prefs.dart';
import '../services/sleep_timer_service.dart';
import 'absorb_slider.dart';
import 'absorbing_shared.dart';
import 'book_detail_sheet.dart';
import 'card_button_config.dart';
import 'card_chapters_sheet.dart';
import 'chromecast_button.dart';
import 'episode_detail_sheet.dart';
import 'episode_list_sheet.dart';
import 'equalizer_sheet.dart';
import 'feature_hint.dart';
import 'notes_sheet.dart';
import 'overlay_toast.dart';
import 'sleep_timer_sheet.dart';

/// Wrapper that gives any child a press-down opacity+scale effect.
class Pressable extends StatefulWidget {
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HitTestBehavior? behavior;
  final Widget child;
  const Pressable({super.key, this.onTap, this.onLongPress, this.behavior, required this.child});
  @override State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.90 : 1.0,
        duration: Duration(milliseconds: _pressed ? 0 : 150),
        child: AnimatedOpacity(
          opacity: _pressed ? 0.4 : 1.0,
          duration: Duration(milliseconds: _pressed ? 0 : 150),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Show a toast when the user taps a button that requires active playback.
void showInactiveToast(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(l.startPlayingSomethingFirst),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
}

/// Show an error message to the user.
void showErrorSnackBar(BuildContext context, String message) {
  showOverlayToast(context, message, icon: Icons.error_outline_rounded);
}

// ─── WIDE GLASS BUTTON (for 2-column grid) ─────────────────

class CardWideButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool isActive;
  final bool alwaysEnabled;
  final bool large;
  final bool compact;
  final bool iconsOnly;
  final bool highlighted;
  final VoidCallback? onTap;
  final Widget? child;

  const CardWideButton({
    super.key,
    required this.icon, required this.label,
    required this.accent, required this.isActive,
    this.alwaysEnabled = false, this.large = false, this.compact = false,
    this.iconsOnly = false, this.highlighted = false, this.onTap, this.child,
  });

  @override Widget build(BuildContext context) {
    if (child != null) return child!;
    final cs = Theme.of(context).colorScheme;
    final enabled = isActive || alwaysEnabled;
    final iconSize = compact ? 13.0 : (large ? 20.0 : 16.0);
    final fontSize = compact ? 10.0 : (large ? 13.0 : 11.0);
    final vPad = compact ? 8.0 : (large ? 14.0 : 10.0);
    final radius = compact ? 10.0 : (large ? 14.0 : 12.0);
    final showIconOnly = compact || iconsOnly;
    final fgColor = highlighted
        ? accent
        : (enabled ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.24));
    return Pressable(
      onTap: enabled ? onTap : () => showInactiveToast(context),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: vPad),
        decoration: BoxDecoration(
          color: highlighted ? accent.withValues(alpha: 0.1) : cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: highlighted ? accent.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: showIconOnly
          ? Center(child: Icon(icon, size: iconSize, color: fgColor))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: iconSize, color: fgColor),
                const SizedBox(width: 6),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(
                  color: fgColor,
                  fontSize: fontSize, fontWeight: FontWeight.w500))),
              ],
            ),
      ),
    );
  }
}

/// Menu item for the More bottom sheet
class MoreMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool enabled;
  final VoidCallback onTap;

  const MoreMenuItem({
    super.key,
    required this.icon, required this.label,
    required this.accent, required this.onTap,
    this.enabled = true,
  });

  @override Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Pressable(
      onTap: enabled ? onTap : () => showInactiveToast(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: enabled ? accent.withValues(alpha: 0.7) : cs.onSurface.withValues(alpha: 0.24)),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(
              color: enabled ? cs.onSurface.withValues(alpha: 0.8) : cs.onSurface.withValues(alpha: 0.24),
              fontSize: 14, fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right_rounded, size: 18, color: enabled ? cs.onSurface.withValues(alpha: 0.24) : cs.onSurface.withValues(alpha: 0.12)),
          ],
        ),
      ),
    );
  }
}

/// Sleep button as wide card with countdown and fill bar
class CardSleepButtonInline extends StatelessWidget {
  final Color accent;
  final bool isActive;
  final bool large;
  final bool compact;
  final bool iconsOnly;
  const CardSleepButtonInline({super.key, required this.accent, required this.isActive, this.large = false, this.compact = false, this.iconsOnly = false});

  @override Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SleepTimerService(),
      builder: (_, __) {
        final cs = Theme.of(context).colorScheme;
        final l = AppLocalizations.of(context)!;
        final sleep = SleepTimerService();
        // Only show timer state on the card that's actually playing
        final active = isActive && sleep.isActive;
        final isTime = sleep.mode == SleepTimerMode.time;

        String label;
        if (active && isTime) {
          final r = sleep.timeRemaining;
          final m = r.inMinutes;
          final s = r.inSeconds % 60;
          label = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        } else if (active) {
          label = l.chaptersLeftCount(sleep.chaptersRemaining);
        } else {
          label = l.timer;
        }

        final h = compact ? 30.0 : (large ? 48.0 : 36.0);
        final iconSz = compact ? 13.0 : (large ? 20.0 : 16.0);
        final fontSize = compact ? 10.0 : (large ? (active && isTime ? 15.0 : 14.0) : (active && isTime ? 13.0 : 12.0));
        final radius = compact ? 10.0 : (large ? 16.0 : 14.0);

        return Pressable(
          onTap: isActive ? () {
            showSleepTimerSheet(context, accent);
          } : () => showInactiveToast(context),
          child: Container(
            height: h,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: active ? accent.withValues(alpha: 0.1) : cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: active ? accent.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Stack(children: [
              if (active && isTime)
                FractionallySizedBox(
                  widthFactor: sleep.timeProgress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(radius - 1),
                    ),
                  ),
                ),
              Center(child: (compact || iconsOnly) && !active
                ? Icon(Icons.nightlight_round_outlined, size: iconSz,
                    color: isActive ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.24))
                : iconsOnly && active
                  ? Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(
                      color: accent,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      fontFeatures: isTime ? const [FontFeature.tabularFigures()] : null,
                    ))
                  : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.nightlight_round_outlined, size: iconSz,
                        color: active ? accent : (isActive ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.24))),
                      SizedBox(width: compact ? 4 : 8),
                      Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(
                        color: active ? accent : (isActive ? cs.onSurfaceVariant : cs.onSurface.withValues(alpha: 0.24)),
                        fontSize: fontSize,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        fontFeatures: active && isTime ? const [FontFeature.tabularFigures()] : null,
                      ))),
                    ],
                  )),
            ]),
          ),
        );
      },
    );
  }
}

/// Download button as wide card
class CardDownloadButtonInline extends StatelessWidget {
  final String itemId;
  final String? episodeId;
  final String title;
  final String? author;
  final String? coverUrl;
  final Color accent;
  final bool large;
  final bool compact;
  final bool iconsOnly;
  const CardDownloadButtonInline({super.key, required this.itemId, this.episodeId, required this.title, this.author, this.coverUrl, required this.accent, this.large = false, this.compact = false, this.iconsOnly = false});

  // Podcast downloads are keyed 'parentId-episodeId'; books use the plain itemId.
  String get _key => episodeId != null ? '$itemId-$episodeId' : itemId;

  @override Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DownloadService(),
      builder: (_, __) {
        final cs = Theme.of(context).colorScheme;
        final l = AppLocalizations.of(context)!;
        final dl = DownloadService();
        final downloading = dl.isDownloading(_key);
        final downloaded = dl.isDownloaded(_key);
        final progress = dl.downloadProgress(_key);

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final dlGreen = isDark ? Colors.greenAccent.withValues(alpha: 0.7) : Colors.green.shade700;

        final IconData icon;
        final String label;
        final Color color;
        if (downloaded) {
          icon = Icons.download_done_rounded;
          label = l.saved;
          color = dlGreen;
        } else if (downloading) {
          icon = Icons.downloading_rounded;
          label = '${(progress * 100).toStringAsFixed(0)}%';
          color = accent;
        } else {
          icon = Icons.download_outlined;
          label = l.download;
          color = cs.onSurfaceVariant;
        }

        final h = compact ? 30.0 : (large ? 48.0 : 36.0);
        final iconSz = compact ? 13.0 : (large ? 20.0 : 16.0);
        final fontSize = compact ? 10.0 : (large ? 14.0 : 12.0);
        final radius = compact ? 10.0 : (large ? 16.0 : 14.0);

        return Pressable(
          onTap: () => _handleTap(context, dl),
          child: Container(
            height: h,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: downloaded ? dlGreen.withValues(alpha: 0.1) : cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: downloaded ? dlGreen.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Stack(children: [
              if (downloading)
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(radius - 1),
                    ),
                  ),
                ),
              Center(child: iconsOnly || (compact && !downloaded && !downloading)
                ? Icon(icon, size: iconSz, color: color)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: iconSz, color: color),
                      SizedBox(width: compact ? 4 : 8),
                      Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(
                        color: color, fontSize: fontSize,
                        fontWeight: downloaded || downloading ? FontWeight.w700 : FontWeight.w500,
                      ))),
                    ],
                  )),
            ]),
          ),
        );
      },
    );
  }

  void _handleTap(BuildContext context, DownloadService dl) async {
    final l = AppLocalizations.of(context)!;
    if (dl.isDownloaded(_key)) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text(l.removeDownloadQuestion),
        content: Text(l.removeDownloadContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(onPressed: () {
            dl.deleteDownload(_key);
            Navigator.pop(ctx);
            showOverlayToast(context, l.downloadRemoved, icon: Icons.delete_outline_rounded);
          }, child: Text(l.remove, style: const TextStyle(color: Colors.redAccent))),
        ],
      ));
    } else if (dl.isDownloading(_key)) {
      dl.cancelDownload(_key);
    } else {
      final auth = context.read<AuthProvider>();
      final api = auth.apiService;
      if (api == null) return;
      final error = await dl.downloadItem(api: api, itemId: itemId, episodeId: episodeId, title: title, author: author, coverUrl: coverUrl, libraryId: context.read<LibraryProvider>().selectedLibraryId);
      if (error != null && context.mounted) {
        showOverlayToast(context, error, icon: Icons.error_outline_rounded);
      }
    }
  }
}

/// Bookmark button as wide card
class CardBookmarkButtonInline extends StatefulWidget {
  final AudioPlayerService player;
  final Color accent;
  final bool isActive;
  final String itemId;
  final bool large;
  final bool compact;
  final bool short;
  final bool iconsOnly;
  const CardBookmarkButtonInline({super.key, required this.player, required this.accent, required this.isActive, required this.itemId, this.large = false, this.compact = false, this.short = false, this.iconsOnly = false});
  @override State<CardBookmarkButtonInline> createState() => _CardBookmarkButtonInlineState();
}

class _CardBookmarkButtonInlineState extends State<CardBookmarkButtonInline> {
  int _count = 0;
  @override void initState() { super.initState(); _syncThenLoadCount(); }

  Future<void> _syncThenLoadCount() async {
    // Show local count immediately
    _loadCount();
    // Then sync with server and update
    final api = AudioPlayerService().currentApi;
    if (api != null) {
      await BookmarkService().syncBookmarks(widget.itemId, api);
      _loadCount();
    }
  }

  Future<void> _loadCount() async {
    final c = await BookmarkService().getCount(widget.itemId);
    if (mounted) setState(() => _count = c);
  }

  @override Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final cp = widget.compact;
    final lg = widget.large;
    final active = widget.isActive || _isCasting;
    final iconSz = cp ? 13.0 : (lg ? 22.0 : 18.0);
    final fontSize = cp ? 10.0 : (lg ? 14.0 : 12.0);
    final vPad = cp ? 6.0 : (lg ? 12.0 : 8.0);
    final radius = cp ? 10.0 : (lg ? 14.0 : 12.0);
    final sh = widget.short;
    final label = cp ? (_count > 0 ? '$_count' : l.bookmark) : sh ? l.bookmarks : (_count > 0 ? l.bookmarksWithCount(_count) : l.bookmark);
    return Pressable(
      onTap: () => _showBookmarks(context),
      onLongPress: active ? () => _quickAdd(context) : null,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: vPad),
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        child: cp || widget.iconsOnly
          ? Center(child: Icon(Icons.bookmark_outline_rounded, size: iconSz, color: cs.onSurfaceVariant))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bookmark_outline_rounded, size: iconSz, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(
                  color: cs.onSurfaceVariant, fontSize: fontSize, fontWeight: FontWeight.w500))),
              ],
            ),
      ),
    );
  }

  bool get _isCasting {
    final cast = ChromecastService();
    return cast.isCasting && cast.castingItemId == widget.itemId;
  }

  void _quickAdd(BuildContext ctx) async {
    final l = AppLocalizations.of(ctx)!;
    final cast = ChromecastService();
    final pos = _isCasting
        ? cast.castPosition.inMilliseconds / 1000.0
        : widget.player.position.inMilliseconds / 1000.0;
    final chapters = _isCasting ? cast.castingChapters : widget.player.chapters;
    String? chTitle;
    for (final ch in chapters) {
      final m = ch as Map<String, dynamic>;
      final s = (m['start'] as num?)?.toDouble() ?? 0;
      final e = (m['end'] as num?)?.toDouble() ?? 0;
      if (pos >= s && pos < e) { chTitle = m['title'] as String?; break; }
    }
    await BookmarkService().addBookmark(itemId: widget.itemId, positionSeconds: pos, title: chTitle ?? l.bookmark, api: AudioPlayerService().currentApi);
    _loadCount();
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text(l.bookmarkAdded), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  void _showBookmarks(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true, useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6, minChildSize: 0.05, snap: true, maxChildSize: 0.9, expand: false,
        builder: (ctx, sc) => SimpleBookmarkSheet(itemId: widget.itemId, player: widget.player, accent: widget.accent, scrollController: sc, onChanged: _loadCount),
      ),
    );
  }
}

/// Speed button as wide card — opens the full speed sheet with slider
class CardSpeedButtonInline extends StatefulWidget {
  final AudioPlayerService player;
  final Color accent;
  final bool isActive;
  final bool large;
  final bool compact;
  final bool iconsOnly;
  final String? itemId;
  const CardSpeedButtonInline({super.key, required this.player, required this.accent, required this.isActive, this.large = false, this.compact = false, this.iconsOnly = false, this.itemId});

  @override State<CardSpeedButtonInline> createState() => _CardSpeedButtonInlineState();
}

class _CardSpeedButtonInlineState extends State<CardSpeedButtonInline> {
  double _savedSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _loadSavedSpeed();
    PlayerSettings.settingsChanged.addListener(_loadSavedSpeed);
  }

  @override
  void dispose() {
    PlayerSettings.settingsChanged.removeListener(_loadSavedSpeed);
    super.dispose();
  }

  Future<void> _loadSavedSpeed() async {
    if (widget.itemId == null) return;
    final bookSpeed = await PlayerSettings.getBookSpeed(widget.itemId!);
    final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
    if (mounted && speed != _savedSpeed) setState(() => _savedSpeed = speed);
  }

  @override Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cast = ChromecastService();
    final h = widget.compact ? 30.0 : (widget.large ? 48.0 : 36.0);
    final iconSz = widget.compact ? 13.0 : (widget.large ? 20.0 : 16.0);
    final fontSize = widget.compact ? 10.0 : (widget.large ? 15.0 : 13.0);
    final radius = widget.compact ? 10.0 : (widget.large ? 16.0 : 14.0);
    return ListenableBuilder(
      listenable: Listenable.merge([cast, widget.player]),
      builder: (context, _) {
        final castNow = widget.itemId != null && cast.isCasting && cast.castingItemId == widget.itemId;
        final speedNow = castNow ? cast.castSpeed : (widget.isActive ? widget.player.speed : _savedSpeed);
        final isDefaultSpeed = (speedNow - 1.0).abs() < 0.01;
        final Widget content;
        if (widget.compact) {
          content = Center(child: Text('${speedNow.toStringAsFixed(1)}x', style: TextStyle(
            color: widget.accent, fontSize: fontSize, fontWeight: FontWeight.w700)));
        } else if (widget.iconsOnly && isDefaultSpeed) {
          content = Center(child: Icon(Icons.speed_rounded, size: iconSz, color: cs.onSurfaceVariant));
        } else if (widget.iconsOnly) {
          content = Center(child: Text(speedNow.toStringAsFixed(2), style: TextStyle(
            color: widget.accent, fontSize: fontSize, fontWeight: FontWeight.w700)));
        } else {
          content = Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.speed_rounded, size: iconSz, color: widget.accent),
              const SizedBox(width: 8),
              Text('${speedNow.toStringAsFixed(2)}x', style: TextStyle(
                color: widget.accent, fontSize: fontSize, fontWeight: FontWeight.w700)),
            ],
          );
        }
        return Pressable(
          onTap: () {
            showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
              useSafeArea: true,
              builder: (ctx) => CardSpeedSheet(player: widget.player, accent: widget.accent, itemId: widget.itemId));
          },
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: content,
          ),
        );
      },
    );
  }
}

// ─── SPEED SHEET ─────────────────────────────────────────────

class CardSpeedSheet extends StatefulWidget {
  final AudioPlayerService player; final Color accent; final String? itemId;
  const CardSpeedSheet({super.key, required this.player, required this.accent, this.itemId});
  @override State<CardSpeedSheet> createState() => _CardSpeedSheetState();
}

class _CardSpeedSheetState extends State<CardSpeedSheet> {
  late double _speed;
  List<double> _presets = List<double>.from(PlayerSettings.defaultSpeedPresets);

  bool get _isCasting {
    final cast = ChromecastService();
    return widget.itemId != null && cast.isCasting && cast.castingItemId == widget.itemId;
  }

  @override void initState() {
    super.initState();
    final initialSpeed = _isCasting ? ChromecastService().castSpeed : widget.player.speed;
    _speed = (initialSpeed * 20).round() / 20.0;
    if (!widget.player.hasBook && !_isCasting) _loadSavedSpeed();
    _loadPresets();
    PlayerSettings.settingsChanged.addListener(_loadPresets);
  }

  @override void dispose() {
    PlayerSettings.settingsChanged.removeListener(_loadPresets);
    super.dispose();
  }

  Future<void> _loadPresets() async {
    final presets = await PlayerSettings.getSpeedPresets();
    if (mounted) setState(() => _presets = presets);
  }

  Future<void> _addCurrentAsPreset() async {
    if (_presets.any((p) => (p - _speed).abs() < 0.01)) return;
    final next = [..._presets, _speed];
    await PlayerSettings.setSpeedPresets(next);
  }

  Future<void> _removePreset(double value) async {
    if (_presets.length <= 1) return;
    final next = _presets.where((p) => (p - value).abs() >= 0.01).toList();
    await PlayerSettings.setSpeedPresets(next);
  }

  Future<void> _loadSavedSpeed() async {
    if (widget.itemId == null) return;
    final bookSpeed = await PlayerSettings.getBookSpeed(widget.itemId!);
    final speed = bookSpeed ?? await PlayerSettings.getDefaultSpeed();
    if (mounted) setState(() => _speed = (speed * 20).round() / 20.0);
  }
  void _setSpeed(double v) {
    final s = (v * 20).round() / 20.0;
    setState(() => _speed = s.clamp(0.5, 3.0));
    if (_isCasting) {
      ChromecastService().setSpeed(_speed);
    } else if (widget.player.hasBook) {
      widget.player.setSpeed(_speed);
    }
    // Always save per-book speed so inactive cards pick it up
    if (widget.itemId != null) {
      PlayerSettings.setBookSpeed(widget.itemId!, _speed);
      PlayerSettings.notifySettingsChanged();
    }
  }

  @override Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    final navBarPad = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + navBarPad),
      decoration: BoxDecoration(color: Theme.of(context).bottomSheetTheme.backgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: widget.accent.withValues(alpha: 0.2), width: 1))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Text(l.playbackSpeed, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('${_speed.toStringAsFixed(2)}x', style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w700, color: widget.accent)),
        const SizedBox(height: 12),
        const FeatureHint(
          prefKey: 'hint_speed_presets',
          message: 'Tap + to save the current speed as a preset. Long-press a chip to remove it.',
          padding: EdgeInsets.fromLTRB(0, 0, 0, 12),
        ),
        Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
          ..._presets.map((s) {
            final a = (_speed - s).abs() < 0.01;
            final canRemove = _presets.length > 1;
            return GestureDetector(
              onTap: () => _setSpeed(s),
              onLongPress: canRemove ? () => _removePreset(s) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: a ? widget.accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: a ? widget.accent : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12))),
                child: Text('${s}x', style: TextStyle(color: a ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), fontSize: 13, fontWeight: a ? FontWeight.w700 : FontWeight.w500)),
              ),
            );
          }),
          GestureDetector(
            onTap: _addCurrentAsPreset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.accent.withValues(alpha: 0.4), style: BorderStyle.solid),
              ),
              child: Icon(Icons.add_rounded, size: 16, color: widget.accent),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          GestureDetector(
            onTap: () => _setSpeed(_speed - 0.05),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
              child: Icon(Icons.remove_rounded, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
          Expanded(child: AbsorbSlider(value: _speed, min: 0.5, max: 3.0, divisions: 50, activeColor: widget.accent, onChanged: _setSpeed)),
          GestureDetector(
            onTap: () => _setSpeed(_speed + 0.05),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
              child: Icon(Icons.add_rounded, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
          ),
        ]),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 36), child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0.5x', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11)),
            Text('3.0x', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), fontSize: 11)),
          ],
        )),
      ]),
    );
  }
}

// ─── BOOKMARK SHEET ──────────────────────────────────────────

class SimpleBookmarkSheet extends StatefulWidget {
  final String itemId; final AudioPlayerService player; final Color accent; final ScrollController scrollController; final VoidCallback onChanged;
  const SimpleBookmarkSheet({super.key, required this.itemId, required this.player, required this.accent, required this.scrollController, required this.onChanged});
  @override State<SimpleBookmarkSheet> createState() => _SimpleBookmarkSheetState();
}

class _SimpleBookmarkSheetState extends State<SimpleBookmarkSheet> {
  List<Bookmark>? _bookmarks;
  String _sort = 'newest';
  @override void initState() { super.initState(); _loadSort(); }
  Future<void> _loadSort() async {
    _sort = await PlayerSettings.getBookmarkSort();
    // Sync first, then load
    final api = AudioPlayerService().currentApi;
    if (api != null) {
      await BookmarkService().syncBookmarks(widget.itemId, api);
    }
    _load();
  }
  Future<void> _load() async {
    final bm = await BookmarkService().getBookmarks(widget.itemId, sort: _sort);
    if (mounted) setState(() => _bookmarks = bm);
    widget.onChanged();
  }

  @override Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: widget.accent.withValues(alpha: 0.2), width: 1)),
      ),
      child: Column(children: [
        Padding(padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2)))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          GestureDetector(
            onTap: () {
              final next = _sort == 'newest' ? 'position'
                  : _sort == 'position' ? 'position_desc'
                  : 'newest';
              setState(() => _sort = next);
              PlayerSettings.setBookmarkSort(next);
              _load();
            },
            child: Tooltip(
              message: _sort == 'newest' ? l.bookmarksSortedByNewest
                  : _sort == 'position' ? l.bookmarksSortedByPosition
                  : l.bookmarksSortedByPositionReversed,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
                child: Icon(
                  _sort == 'newest' ? Icons.schedule_rounded
                      : _sort == 'position' ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: cs.onSurfaceVariant, size: 20,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(l.bookmarks, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(onTap: () => _addBookmark(), child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: widget.accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.add_rounded, color: widget.accent, size: 20),
          )),
        ])),
        const SizedBox(height: 8),
        Expanded(child: _bookmarks == null
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _bookmarks!.isEmpty
                ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.bookmark_outline_rounded, size: 48, color: cs.onSurface.withValues(alpha: 0.1)),
                    const SizedBox(height: 12),
                    Text(l.noBookmarksYet, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(l.longPressBookmarkHint, style: tt.bodySmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.24), fontSize: 11)),
                  ]))
                : ListView.builder(
                    controller: widget.scrollController, padding: const EdgeInsets.only(bottom: 24), itemCount: _bookmarks!.length,
                    itemBuilder: (ctx, i) {
                      final bm = _bookmarks![i];
                      final hasNote = bm.note != null && bm.note!.isNotEmpty;
                      return InkWell(
                        onTap: () async {
                          final confirmed = await showDialog<bool>(context: ctx, builder: (dlg) => AlertDialog(
                            title: Text(l.bookmarksJumpTitle),
                            content: Text(l.bookmarksJumpShortContent(bm.title, bm.formattedPosition)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(dlg, false), child: Text(l.cancel)),
                              FilledButton(onPressed: () => Navigator.pop(dlg, true), child: Text(l.bookmarksJump)),
                            ],
                          ));
                          if (confirmed != true || !ctx.mounted) return;
                          final isActive = widget.player.currentItemId == widget.itemId;
                          Navigator.pop(ctx); // Close bookmark sheet first
                          if (isActive || _isCasting) {
                            final seekDur = Duration(seconds: bm.positionSeconds.round());
                            if (_isCasting) {
                              ChromecastService().seekTo(seekDur);
                            } else {
                              await widget.player.seekTo(seekDur);
                              if (!widget.player.isPlaying) widget.player.play();
                            }
                          } else {
                            await _startPlaybackAt(bm.positionSeconds);
                          }
                        },
                        onLongPress: () => _editBookmark(bm),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(Icons.bookmark_rounded, size: 20, color: widget.accent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(bm.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: tt.bodyMedium?.copyWith(color: cs.onSurface.withValues(alpha: 0.7))),
                              const SizedBox(height: 2),
                              Text(bm.formattedPosition, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                              if (hasNote) ...[
                                const SizedBox(height: 4),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: cs.onSurface.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(bm.note!, maxLines: 3, overflow: TextOverflow.ellipsis,
                                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontSize: 11, height: 1.4)),
                                ),
                              ],
                            ])),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () async {
                                final confirmed = await showDialog<bool>(context: context, builder: (dlg) => AlertDialog(
                                  title: Text(l.deleteBookmarkQuestion),
                                  content: Text(l.bookmarksJumpShortContent(bm.title, bm.formattedPosition)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dlg, false), child: Text(l.cancel)),
                                    TextButton(onPressed: () => Navigator.pop(dlg, true), child: Text(l.delete, style: TextStyle(color: Colors.red.shade300))),
                                  ],
                                ));
                                if (confirmed != true) return;
                                await BookmarkService().deleteBookmark(itemId: widget.itemId, bookmarkId: bm.id, api: AudioPlayerService().currentApi);
                                _load();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Icon(Icons.delete_outline_rounded, size: 22, color: cs.onSurface.withValues(alpha: 0.35)),
                              ),
                            ),
                          ]),
                        ),
                      );
                    })),
      ]),
    );
  }

  bool get _isCasting {
    final cast = ChromecastService();
    return cast.isCasting && cast.castingItemId == widget.itemId;
  }

  Future<void> _startPlaybackAt(double positionSeconds) async {
    final api = context.read<AuthProvider>().apiService;
    if (api == null) return;
    final lib = context.read<LibraryProvider>();
    final player = widget.player;
    final fullItem = await api.getLibraryItem(widget.itemId);
    if (fullItem == null) return;
    final media = fullItem['media'] as Map<String, dynamic>? ?? {};
    final metadata = media['metadata'] as Map<String, dynamic>? ?? {};
    final title = metadata['title'] as String? ?? '';
    final author = metadata['authorName'] as String? ?? '';
    final coverUrl = lib.getCoverUrl(widget.itemId);
    final duration = (media['duration'] is num) ? (media['duration'] as num).toDouble() : 0.0;
    final chapters = (media['chapters'] as List<dynamic>?) ?? [];
    await player.playItem(
      api: api, itemId: widget.itemId,
      title: title, author: author, coverUrl: coverUrl,
      totalDuration: duration, chapters: chapters,
      startTime: positionSeconds, forceStartTime: true,
    );
    AppShell.goToAbsorbingGlobal();
  }

  Future<void> _addBookmark() async {
    final l = AppLocalizations.of(context)!;
    final cast = ChromecastService();
    final pos = _isCasting
        ? cast.castPosition.inMilliseconds / 1000.0
        : widget.player.position.inMilliseconds / 1000.0;
    final h = pos ~/ 3600; final m = (pos % 3600) ~/ 60; final s = pos.toInt() % 60;
    final posStr = h > 0 ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}' : '$m:${s.toString().padLeft(2, '0')}';

    // Find current chapter name for default title
    final chapters = _isCasting ? cast.castingChapters : widget.player.chapters;
    String defaultTitle = l.bookmarkAtPosition(posStr);
    for (final ch in chapters) {
      final cm = ch as Map<String, dynamic>;
      final cs = (cm['start'] as num?)?.toDouble() ?? 0;
      final ce = (cm['end'] as num?)?.toDouble() ?? 0;
      if (pos >= cs && pos < ce) { defaultTitle = cm['title'] as String? ?? defaultTitle; break; }
    }

    final titleC = TextEditingController(text: defaultTitle);
    final noteC = TextEditingController();
    final result = await showDialog<Map<String, String>>(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.addBookmark),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleC, autofocus: true, decoration: InputDecoration(labelText: l.titleLabel, border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: noteC, maxLines: 3, decoration: InputDecoration(labelText: l.noteOptionalLabel, border: const OutlineInputBorder(), alignLabelWithHint: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, {'title': titleC.text, 'note': noteC.text}), child: Text(l.save)),
      ],
    ));
    if (result != null && result['title']!.isNotEmpty) {
      final note = result['note']?.isNotEmpty == true ? result['note'] : null;
      await BookmarkService().addBookmark(itemId: widget.itemId, positionSeconds: pos, title: result['title']!, note: note, api: AudioPlayerService().currentApi);
      _load();
    }
  }

  Future<void> _editBookmark(Bookmark bm) async {
    final l = AppLocalizations.of(context)!;
    final titleC = TextEditingController(text: bm.title);
    final noteC = TextEditingController(text: bm.note ?? '');
    final result = await showDialog<Map<String, String>>(context: context, builder: (ctx) => AlertDialog(
      title: Text(l.editBookmark),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: titleC, decoration: InputDecoration(labelText: l.titleLabel, border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        TextField(controller: noteC, maxLines: 3, decoration: InputDecoration(labelText: l.noteOptionalLabel, border: const OutlineInputBorder(), alignLabelWithHint: true)),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, {'title': titleC.text, 'note': noteC.text}), child: Text(l.save)),
      ],
    ));
    if (result != null && result['title']!.isNotEmpty) {
      await BookmarkService().updateBookmark(
        itemId: widget.itemId, bookmarkId: bm.id,
        title: result['title']!, note: result['note']?.isNotEmpty == true ? result['note'] : null,
        api: AudioPlayerService().currentApi,
      );
      _load();
    }
  }
}

// ─── MORE MENU SHEET (with edit/reorder mode) ────────────────

class MoreMenuSheet extends StatefulWidget {
  final List<String> overflowIds;
  final List<String> allIds;
  final int visibleCount;
  final Color accent;
  final Widget Function(String id) buildItem;
  final void Function(List<String>, int) onReorder;
  const MoreMenuSheet({super.key, required this.overflowIds, required this.allIds, this.visibleCount = 4, required this.accent, required this.buildItem, required this.onReorder});
  @override State<MoreMenuSheet> createState() => _MoreMenuSheetState();
}

class _MoreMenuSheetState extends State<MoreMenuSheet> {
  bool _editing = false;
  late List<String> _order;
  late int _visibleCount;
  bool _iconsOnly = false;
  bool _moreInline = false;

  @override
  void initState() {
    super.initState();
    _order = List.from(widget.allIds);
    _visibleCount = widget.visibleCount;
    _loadToggles();
  }

  void _loadToggles() async {
    final io = await PlayerSettings.getCardIconsOnly();
    final mi = await PlayerSettings.getCardMoreInline();
    if (mounted) setState(() {
      _iconsOnly = io; _moreInline = mi;
      if (mi && !_order.contains('_more')) {
        final insertAt = (_visibleCount >= 9 ? 8 : _visibleCount).clamp(0, _order.length);
        _order.insert(insertAt, '_more');
        _visibleCount = (_visibleCount < 9 ? _visibleCount + 1 : 9);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    if (_editing) return _buildEditMode(cs, tt);
    return _buildNormalMode(cs, tt);
  }

  Widget _buildNormalMode(ColorScheme cs, TextTheme tt) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: widget.accent.withValues(alpha: 0.2), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: cs.onSurface.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(2))),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => setState(() => _editing = true),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.edit_rounded, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (int i = 0; i < widget.overflowIds.length; i++) ...[
                widget.buildItem(widget.overflowIds[i]),
                if (i < widget.overflowIds.length - 1) const SizedBox(height: 6),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditMode(ColorScheme cs, TextTheme tt) {
    final l = AppLocalizations.of(context)!;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: BoxDecoration(
        color: Theme.of(context).bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: widget.accent.withValues(alpha: 0.2), width: 1)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(children: [
                Text(l.editLayout, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.check_rounded, color: widget.accent),
                  onPressed: () {
                    // Ensure _more stays in visible zone
                    final moreIdx = _order.indexOf('_more');
                    if (moreIdx >= 0 && moreIdx >= _visibleCount) {
                      _order.remove('_more');
                      final insertAt = (_visibleCount >= 9 ? 8 : _visibleCount - 1).clamp(0, _order.length);
                      _order.insert(insertAt, '_more');
                    }
                    widget.onReorder(List.from(_order), _visibleCount);
                    Navigator.pop(context);
                  },
                ),
              ]),
            ),
            // Toggles
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: Wrap(spacing: 8, runSpacing: 4, children: [
                FilterChip(
                  label: Text(l.cardIconsOnlyChip, style: const TextStyle(fontSize: 12)),
                  selected: _iconsOnly,
                  onSelected: (v) { setState(() => _iconsOnly = v); PlayerSettings.setCardIconsOnly(v); },
                  selectedColor: widget.accent.withValues(alpha: 0.2),
                  checkmarkColor: widget.accent,
                  visualDensity: VisualDensity.compact,
                ),
                FilterChip(
                  label: Text(l.cardMoreInGridChip, style: const TextStyle(fontSize: 12)),
                  selected: _moreInline,
                  onSelected: (v) {
                    setState(() {
                      _moreInline = v;
                      if (v && !_order.contains('_more')) {
                        // Insert _more as last visible slot, pushing that button to hidden if at cap
                        final insertAt = (_visibleCount >= 9 ? 8 : _visibleCount).clamp(0, _order.length);
                        _order.insert(insertAt, '_more');
                        _visibleCount = (_visibleCount < 9 ? _visibleCount + 1 : 9);
                      } else if (!v && _order.contains('_more')) {
                        final idx = _order.indexOf('_more');
                        _order.remove('_more');
                        if (idx < _visibleCount) _visibleCount--;
                        if (_visibleCount < 1) _visibleCount = 1;
                      }
                    });
                    PlayerSettings.setCardMoreInline(v);
                  },
                  selectedColor: widget.accent.withValues(alpha: 0.2),
                  checkmarkColor: widget.accent,
                  visualDensity: VisualDensity.compact,
                ),
              ]),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                buildDefaultDragHandles: false,
                onReorderStart: (_) => HapticFeedback.mediumImpact(),
                proxyDecorator: (child, index, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (context, child) => Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(12),
                      color: cs.surfaceContainer,
                      child: child,
                    ),
                    child: child,
                  );
                },
                // +1 slot for the section divider, rendered as its own non-draggable item
                // at index == _visibleCount. Giving the divider its own slot lets users drop
                // at the top of hidden / bottom of visible without the `newIdx--` adjustment
                // swallowing the drop zone, and keeps the section header from dragging along
                // with the first hidden item.
                itemCount: _order.length + 1,
                onReorder: (oldIdx, newIdx) {
                  // Divider is not draggable, so oldIdx should never equal _visibleCount.
                  if (oldIdx == _visibleCount) return;
                  if (newIdx > oldIdx) newIdx--;
                  setState(() {
                    // Build a combined list with a sentinel at the divider position,
                    // simulate the move, then derive new _order and _visibleCount
                    // from where the sentinel lands.
                    const div = '__DIV__';
                    final combined = <String>[];
                    for (int i = 0; i <= _order.length; i++) {
                      if (i == _visibleCount) combined.add(div);
                      if (i < _order.length) combined.add(_order[i]);
                    }
                    final moved = combined.removeAt(oldIdx);
                    final insertAt = newIdx.clamp(0, combined.length);
                    combined.insert(insertAt, moved);

                    final newDivIdx = combined.indexOf(div);
                    combined.removeAt(newDivIdx);

                    // Constraints: at least 1 visible, _more stays visible, cap 9 visible
                    int newVisible = newDivIdx;
                    if (newVisible < 1) return;
                    if (newVisible > 9) return;
                    if (newVisible > combined.length) newVisible = combined.length;
                    final moreIdx = combined.indexOf('_more');
                    if (moreIdx != -1 && moreIdx >= newVisible) return;

                    _order
                      ..clear()
                      ..addAll(combined);
                    _visibleCount = newVisible;
                  });
                },
                itemBuilder: (context, i) {
                  // Divider slot - rendered as its own non-draggable list item.
                  if (i == _visibleCount) {
                    return Padding(
                      key: const ValueKey('__DIV__'),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(children: [
                        Expanded(child: Divider(color: cs.onSurface.withValues(alpha: 0.12))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(_moreInline ? l.cardLayoutHidden : l.inMenu,
                            style: tt.labelSmall?.copyWith(color: cs.onSurface.withValues(alpha: 0.4))),
                        ),
                        Expanded(child: Divider(color: cs.onSurface.withValues(alpha: 0.12))),
                      ]),
                    );
                  }

                  final orderIdx = i < _visibleCount ? i : i - 1;
                  final id = _order[orderIdx];
                  final isMore = id == '_more';
                  final def = isMore ? null : buttonDefById(id);
                  if (def == null && !isMore) return SizedBox.shrink(key: ValueKey(id));

                  final isOnCard = orderIdx < _visibleCount;

                  return Padding(
                    key: ValueKey(id),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isOnCard ? widget.accent.withValues(alpha: 0.08) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        Icon(isMore ? Icons.more_horiz_rounded : def!.icon, size: 20,
                          color: id == 'remove' ? Colors.red.shade300 : cs.onSurface.withValues(alpha: 0.7)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(isMore ? l.more : localizedCardButtonLabel(l, def!), style: tt.bodyMedium)),
                        if (isOnCard)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text('${orderIdx + 1}', style: tt.labelSmall?.copyWith(color: widget.accent, fontWeight: FontWeight.w700)),
                          ),
                        ReorderableDragStartListener(
                          index: i,
                          child: Icon(Icons.drag_handle_rounded, size: 20, color: cs.onSurface.withValues(alpha: 0.3)),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Shared action delegate for absorbing card & expanded card
// Eliminates duplicated button/sheet logic between the two.
// ═══════════════════════════════════════════════════════════════

class CardActionDelegate {
  final BuildContext context;
  final AudioPlayerService player;
  final Map<String, dynamic> item;
  final String itemId;
  final String? episodeId;
  final bool isPodcastEpisode;
  final String title;
  final String? author;
  final String? coverUrl;
  final double duration;
  final double effectiveDuration;
  final List<dynamic> chapters;
  final Map<String, dynamic>? recentEpisode;
  final bool isActive;
  final bool isPlaybackActive;
  final bool isCastingThis;
  final bool speedAdjustedTime;
  final double savedSpeed;
  final int visibleCount;
  final bool iconsOnly;
  final bool moreInline;
  final List<String> buttonOrder;
  final VoidCallback removeFromAbsorbing;
  final VoidCallback? onRemoveExtra;
  final void Function(List<String>, int) onReorder;

  CardActionDelegate({
    required this.context,
    required this.player,
    required this.item,
    required this.itemId,
    this.episodeId,
    this.isPodcastEpisode = false,
    required this.title,
    this.author,
    this.coverUrl,
    required this.duration,
    required this.effectiveDuration,
    required this.chapters,
    this.recentEpisode,
    required this.isActive,
    required this.isPlaybackActive,
    required this.isCastingThis,
    required this.speedAdjustedTime,
    required this.savedSpeed,
    required this.visibleCount,
    this.iconsOnly = false,
    this.moreInline = false,
    required this.buttonOrder,
    required this.removeFromAbsorbing,
    this.onRemoveExtra,
    required this.onReorder,
  });

  Map<String, dynamic> get _media => item['media'] as Map<String, dynamic>? ?? {};

  int get visibleButtonCount => visibleCount;

  // Predefined row groupings per button count.
  // Labels: max 3 per row. Icons: max 4 per row (5 allowed at count=5).
  static const _labelRows = <int, List<int>>{
    1: [1], 2: [2], 3: [3], 4: [2, 2], 5: [2, 3],
    6: [3, 3], 7: [2, 2, 3], 8: [2, 3, 3], 9: [3, 3, 3],
  };
  static const _iconRows = <int, List<int>>{
    1: [1], 2: [2], 3: [3], 4: [4], 5: [5], 6: [3, 3],
    7: [3, 4], 8: [4, 4], 9: [3, 3, 3],
  };

  List<Widget> buildButtonGrid(Color accent, TextTheme tt) {
    final count = visibleButtonCount;
    final ids = buttonOrder.take(count).toList();
    final n = ids.length;
    if (n == 0) return [];

    final compact = false;
    final short = iconsOnly || n >= 3;

    final table = iconsOnly ? _iconRows : _labelRows;
    final rowSizes = table[n] ?? _labelRows[n] ?? [n];

    final rows = <Widget>[];
    int offset = 0;
    for (int r = 0; r < rowSizes.length; r++) {
      if (r > 0) rows.add(const SizedBox(height: 6));
      final rowLen = rowSizes[r];
      final rowSlots = ids.sublist(offset, (offset + rowLen).clamp(0, n));
      offset += rowLen;

      Widget row = Row(children: [
        for (int c = 0; c < rowSlots.length; c++) ...[
          if (c > 0) const SizedBox(width: 8),
          Expanded(child: rowSlots[c] == '_more'
              ? _buildInlineMoreButton(accent, compact: compact, short: short)
              : buildCardButton(rowSlots[c], accent, tt, compact: compact, short: short, iconsOnly: iconsOnly)),
        ],
      ]);

      // Center single-button rows at 1/3 width
      if (rowSlots.length == 1 && n == 1) {
        row = FractionallySizedBox(widthFactor: 0.34, child: row);
      }

      rows.add(row);
    }
    return rows;
  }

  Widget _buildInlineMoreButton(Color accent, {bool compact = false, bool short = false}) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final large = MediaQuery.sizeOf(context).height > 700;
    final h = compact ? 30.0 : (large ? 48.0 : 36.0);
    final iconSz = compact ? 13.0 : (large ? 20.0 : 16.0);
    final fontSize = compact ? 10.0 : (large ? 13.0 : 11.0);
    final vPad = compact ? 8.0 : (large ? 14.0 : 10.0);
    final radius = compact ? 10.0 : (large ? 14.0 : 12.0);
    return ListenableBuilder(
      listenable: ChromecastService(),
      builder: (_, __) {
        final castActive = ChromecastService().isCasting &&
            !buttonOrder.take(visibleCount).contains('cast');
        final iconColor = castActive ? accent : cs.onSurfaceVariant;
        final moreIcon = castActive ? Icons.cast_connected_rounded : Icons.more_horiz_rounded;
        return Pressable(
          onTap: () => showMoreMenu(accent, Theme.of(context).textTheme),
          child: Container(
            height: h,
            padding: EdgeInsets.symmetric(vertical: vPad),
            decoration: BoxDecoration(
              color: castActive ? accent.withValues(alpha: 0.1) : cs.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: castActive ? accent.withValues(alpha: 0.3) : cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: iconsOnly
              ? Center(child: Icon(moreIcon, size: iconSz, color: iconColor))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(moreIcon, size: iconSz, color: iconColor),
                    const SizedBox(width: 6),
                    Flexible(child: Text(castActive ? l.casting : l.more, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: iconColor, fontSize: fontSize, fontWeight: FontWeight.w500))),
                  ],
                ),
          ),
        );
      },
    );
  }

  /// True when this card's EQ is actively shaping audio:
  /// - global EQ mode: any card glows when the single EQ is on
  /// - per-book mode: only cards whose book has saved EQ enabled
  Future<bool> _resolveEqHighlight(EqualizerService eq, String id) async {
    if (!eq.perItem) return eq.enabled;
    if (id == eq.currentItemId) return eq.enabled;
    final snap = await eq.loadItemSnapshot(id);
    return snap['enabled'] as bool;
  }

  Widget buildCardButton(String id, Color accent, TextTheme tt, {bool compact = false, bool short = false, bool iconsOnly = false}) {
    final large = MediaQuery.sizeOf(context).height > 700;
    final l = AppLocalizations.of(context)!;
    switch (id) {
      case 'chapters':
        return CardWideButton(
          icon: Icons.list_rounded, label: l.chapters,
          accent: accent, isActive: true, alwaysEnabled: true, large: large, compact: compact, iconsOnly: iconsOnly,
          onTap: chapters.isNotEmpty ? () => showChapters(context, accent, tt) : null,
        );
      case 'speed':
        return CardWideButton(
          icon: Icons.speed_rounded, label: l.speed,
          accent: accent, isActive: isPlaybackActive, large: large, compact: compact, iconsOnly: iconsOnly,
          child: CardSpeedButtonInline(player: player, accent: accent, isActive: isActive, large: large, compact: compact, iconsOnly: iconsOnly, itemId: itemId),
        );
      case 'sleep':
        return CardWideButton(
          icon: Icons.nightlight_round_outlined, label: l.timer,
          accent: accent, isActive: true, alwaysEnabled: true, large: large, compact: compact, iconsOnly: iconsOnly,
          child: CardSleepButtonInline(accent: accent, isActive: isPlaybackActive, large: large, compact: compact, iconsOnly: iconsOnly),
        );
      case 'bookmarks':
        return CardWideButton(
          icon: Icons.bookmark_outline_rounded, label: l.bookmarks,
          accent: accent, isActive: isPlaybackActive, large: large, compact: compact, iconsOnly: iconsOnly,
          child: CardBookmarkButtonInline(
            player: player, accent: accent,
            isActive: isActive, itemId: itemId, large: large, compact: compact, short: short, iconsOnly: iconsOnly,
          ),
        );
      case 'details':
        return CardWideButton(
          icon: (episodeId != null || isPodcastEpisode) ? Icons.podcasts_rounded : Icons.info_outline_rounded,
          label: short ? l.details : ((episodeId != null || isPodcastEpisode) ? l.episodeDetailsLabel : l.bookDetailsLabel),
          accent: accent, isActive: true, alwaysEnabled: true, large: large, compact: compact, iconsOnly: iconsOnly,
          onTap: () => _openDetails(),
        );
      case 'equalizer':
        return ListenableBuilder(
          listenable: EqualizerService(),
          builder: (_, __) {
            final eq = EqualizerService();
            return FutureBuilder<bool>(
              future: _resolveEqHighlight(eq, itemId),
              builder: (_, snap) {
                final highlighted = snap.data ?? false;
                return CardWideButton(
                  icon: Icons.equalizer_rounded, label: compact ? l.equalizerShort : l.equalizerLabel,
                  accent: accent, isActive: true, alwaysEnabled: true,
                  highlighted: highlighted,
                  large: large, compact: compact, iconsOnly: iconsOnly,
                  onTap: () => showEqualizerSheet(context, accent, itemId: itemId, itemTitle: title),
                );
              },
            );
          },
        );
      case 'cast':
        return ListenableBuilder(
          listenable: ChromecastService(),
          builder: (_, __) {
            final cast = ChromecastService();
            final String castLabel;
            if (compact || short) {
              castLabel = cast.isConnected ? l.casting : l.cast;
            } else if (cast.isCasting && cast.castingItemId == itemId) {
              castLabel = l.castingToDevice(cast.connectedDeviceName ?? 'device');
            } else if (cast.isConnected) {
              castLabel = l.castToDeviceNamed(cast.connectedDeviceName ?? 'device');
            } else {
              castLabel = l.castToDevice;
            }
            return CardWideButton(
              icon: cast.isConnected ? Icons.cast_connected_rounded : Icons.cast_rounded,
              label: castLabel, accent: accent, isActive: true, alwaysEnabled: true, large: large, compact: compact, iconsOnly: iconsOnly,
              onTap: () => handleCastTap(context, accent),
            );
          },
        );
      case 'history':
        return CardWideButton(
          icon: Icons.history_rounded, label: (compact || short) ? l.historyShort : l.playbackHistory,
          accent: accent, isActive: true, alwaysEnabled: true, large: large, compact: compact, iconsOnly: iconsOnly,
          onTap: () => showHistory(context, accent, tt),
        );
      case 'remove':
        return CardWideButton(
          icon: Icons.remove_circle_outline_rounded, label: (compact || short) ? l.remove : l.removeFromAbsorbing,
          accent: Colors.red.shade300, isActive: true, alwaysEnabled: true, large: large, compact: compact, iconsOnly: iconsOnly,
          onTap: () { removeFromAbsorbing(); onRemoveExtra?.call(); },
        );
      case 'car':
        return CardWideButton(
          icon: Icons.directions_car_rounded, label: l.carModeTitle,
          accent: accent, isActive: true, alwaysEnabled: true, large: large, compact: compact, iconsOnly: iconsOnly,
          onTap: () => openCarMode(context),
        );
      case 'notes':
        return CardWideButton(
          icon: Icons.note_rounded, label: l.notes,
          accent: accent, isActive: true, alwaysEnabled: true, large: large, compact: compact, iconsOnly: iconsOnly,
          onTap: () => showNotes(context, accent),
        );
      case 'download':
        return CardWideButton(
          icon: Icons.download_outlined, label: l.download,
          accent: accent, isActive: true, alwaysEnabled: true, large: large, compact: compact, iconsOnly: iconsOnly,
          child: CardDownloadButtonInline(
            itemId: itemId, episodeId: episodeId,
            title: title, author: author, coverUrl: coverUrl,
            accent: accent, large: large, compact: compact, iconsOnly: iconsOnly,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget buildMoreMenuItem(String id, Color accent, TextTheme tt, BuildContext ctx) {
    final l = AppLocalizations.of(context)!;
    switch (id) {
      case 'chapters':
        return MoreMenuItem(
          icon: Icons.list_rounded, label: l.chapters, accent: accent,
          enabled: chapters.isNotEmpty,
          onTap: () { Navigator.pop(ctx); showChapters(context, accent, tt); },
        );
      case 'speed':
        return MoreMenuItem(
          icon: Icons.speed_rounded, label: l.speed, accent: accent,
          enabled: true,
          onTap: () {
            Navigator.pop(ctx);
            showModalBottomSheet(context: context, backgroundColor: Colors.transparent, useSafeArea: true,
              builder: (_) => CardSpeedSheet(player: player, accent: accent, itemId: itemId));
          },
        );
      case 'sleep':
        return MoreMenuItem(
          icon: Icons.nightlight_round_outlined, label: l.timer, accent: accent,
          enabled: true,
          onTap: () {
            Navigator.pop(ctx);
            showSleepTimerSheet(context, accent);
          },
        );
      case 'bookmarks':
        return MoreMenuItem(
          icon: Icons.bookmark_outline_rounded, label: l.bookmarks, accent: accent,
          enabled: isPlaybackActive,
          onTap: () {
            Navigator.pop(ctx);
            showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, useSafeArea: true,
              builder: (_) => DraggableScrollableSheet(
                initialChildSize: 0.6, minChildSize: 0.05, snap: true, maxChildSize: 0.9, expand: false,
                builder: (_, sc) => SimpleBookmarkSheet(itemId: itemId, player: player, accent: accent, scrollController: sc, onChanged: () {}),
              ),
            );
          },
        );
      case 'details':
        return MoreMenuItem(
          icon: (episodeId != null || isPodcastEpisode) ? Icons.podcasts_rounded : Icons.info_outline_rounded,
          label: (episodeId != null || isPodcastEpisode) ? l.episodeDetailsLabel : l.bookDetailsLabel,
          accent: accent,
          onTap: () { Navigator.pop(ctx); _openDetails(); },
        );
      case 'equalizer':
        return MoreMenuItem(
          icon: Icons.equalizer_rounded, label: l.equalizerLabel, accent: accent,
          onTap: () { Navigator.pop(ctx); showEqualizerSheet(context, accent, itemId: itemId, itemTitle: title); },
        );
      case 'cast':
        return ListenableBuilder(
          listenable: ChromecastService(),
          builder: (_, __) {
            final cast = ChromecastService();
            final String castLabel;
            if (cast.isCasting && cast.castingItemId == itemId) {
              castLabel = l.castingToDevice(cast.connectedDeviceName ?? 'device');
            } else if (cast.isConnected) {
              castLabel = l.castToDeviceNamed(cast.connectedDeviceName ?? 'device');
            } else {
              castLabel = l.castToDevice;
            }
            return MoreMenuItem(
              icon: cast.isConnected ? Icons.cast_connected_rounded : Icons.cast_rounded,
              label: castLabel, accent: accent,
              onTap: () { Navigator.pop(ctx); handleCastTap(context, accent); },
            );
          },
        );
      case 'history':
        return MoreMenuItem(
          icon: Icons.history_rounded, label: l.playbackHistory, accent: accent,
          enabled: true,
          onTap: () { Navigator.pop(ctx); showHistory(context, accent, tt); },
        );
      case 'remove':
        return MoreMenuItem(
          icon: Icons.remove_circle_outline_rounded, label: l.removeFromAbsorbing,
          accent: Colors.red.shade300,
          onTap: () { Navigator.pop(ctx); removeFromAbsorbing(); onRemoveExtra?.call(); },
        );
      case 'car':
        return MoreMenuItem(
          icon: Icons.directions_car_rounded, label: l.carModeTitle, accent: accent,
          onTap: () { Navigator.pop(ctx); openCarMode(context); },
        );
      case 'notes':
        return MoreMenuItem(
          icon: Icons.note_rounded, label: l.notes, accent: accent,
          onTap: () { Navigator.pop(ctx); showNotes(context, accent); },
        );
      case 'download':
        return ListenableBuilder(
          listenable: DownloadService(),
          builder: (_, __) {
            final dl = DownloadService();
            final dlKey = episodeId != null ? '$itemId-$episodeId' : itemId;
            final downloaded = dl.isDownloaded(dlKey);
            final downloading = dl.isDownloading(dlKey);
            final progress = dl.downloadProgress(dlKey);
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final dlGreen = isDark ? Colors.greenAccent.withValues(alpha: 0.7) : Colors.green.shade700;
            final String dlLabel;
            final IconData dlIcon;
            final Color dlAccent;
            if (downloaded) {
              dlIcon = Icons.download_done_rounded; dlLabel = l.saved; dlAccent = dlGreen;
            } else if (downloading) {
              dlIcon = Icons.downloading_rounded; dlLabel = '${(progress * 100).toStringAsFixed(0)}%'; dlAccent = accent;
            } else {
              dlIcon = Icons.download_outlined; dlLabel = l.download; dlAccent = accent;
            }
            return MoreMenuItem(
              icon: dlIcon, label: dlLabel, accent: dlAccent,
              onTap: () {
                Navigator.pop(ctx);
                final dl = DownloadService();
                if (dl.isDownloaded(dlKey)) {
                  showDialog(context: context, builder: (dCtx) => AlertDialog(
                    title: Text(l.removeDownloadQuestion),
                    content: Text(l.removeDownloadContent),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dCtx), child: Text(l.cancel)),
                      TextButton(onPressed: () {
                        dl.deleteDownload(dlKey);
                        Navigator.pop(dCtx);
                        showOverlayToast(context, l.downloadRemoved, icon: Icons.delete_outline_rounded);
                      }, child: Text(l.remove, style: const TextStyle(color: Colors.redAccent))),
                    ],
                  ));
                } else if (dl.isDownloading(dlKey)) {
                  dl.cancelDownload(dlKey);
                } else {
                  final auth = context.read<AuthProvider>();
                  final api = auth.apiService;
                  if (api == null) return;
                  dl.downloadItem(api: api, itemId: itemId, episodeId: episodeId, title: title, author: author, coverUrl: coverUrl, libraryId: context.read<LibraryProvider>().selectedLibraryId).then((error) {
                    if (error != null && context.mounted) {
                      showOverlayToast(context, error, icon: Icons.error_outline_rounded);
                    }
                  });
                }
              },
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void showMoreMenu(Color accent, TextTheme tt) {
    final count = visibleButtonCount;
    final overflowIds = buttonOrder.skip(count).where((id) => id != '_more').toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => MoreMenuSheet(
        overflowIds: overflowIds,
        allIds: buttonOrder,
        visibleCount: count,
        accent: accent,
        buildItem: (id) => buildMoreMenuItem(id, accent, tt, ctx),
        onReorder: (order, newCount) => onReorder(order, newCount),
      ),
    );
  }

  void showNotes(BuildContext ctx, Color accent) {
    NotesSheet.show(ctx, itemId: itemId, itemTitle: title, accent: accent);
  }

  void openCarMode(BuildContext ctx) {
    Navigator.of(ctx).push(MaterialPageRoute(
      builder: (_) => CarModeScreen(
        player: player,
        itemId: itemId,
        fallbackTitle: title,
        fallbackAuthor: author,
        fallbackCoverUrl: coverUrl,
        fallbackDuration: effectiveDuration,
        fallbackChapters: chapters,
        episodeId: episodeId,
        episodeTitle: recentEpisode?['title'] as String?,
      ),
    ));
  }

  void handleCastTap(BuildContext ctx, Color accent) {
    final cast = ChromecastService();
    final auth = ctx.read<AuthProvider>();
    final api = auth.apiService;
    if (cast.isCasting && cast.castingItemId == itemId) {
      showModalBottomSheet(
        context: ctx,
        backgroundColor: Theme.of(ctx).bottomSheetTheme.backgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => CastControlSheet(),
      );
    } else if (cast.isConnected) {
      if (api != null) {
        cast.castItem(
          api: api, itemId: itemId, title: title, author: author ?? '',
          coverUrl: coverUrl, totalDuration: duration, chapters: chapters,
          episodeId: episodeId ?? player.currentEpisodeId,
        );
      }
    } else {
      showCastDevicePicker(ctx,
        api: api, itemId: itemId, title: title, author: author ?? '',
        coverUrl: coverUrl, totalDuration: duration, chapters: chapters,
        episodeId: episodeId ?? player.currentEpisodeId);
    }
  }

  void showChapters(BuildContext ctx, Color accent, TextTheme tt) {
    final cast = ChromecastService();
    final chaps = isCastingThis ? cast.castingChapters : (isActive ? player.chapters : chapters);
    if (chaps.isEmpty) return;
    double pos = 0;
    if (isCastingThis) {
      pos = cast.castPosition.inMilliseconds / 1000.0;
    } else if (isActive) {
      pos = player.position.inMilliseconds / 1000.0;
    } else {
      final lib = ctx.read<LibraryProvider>();
      final pd = episodeId != null
          ? lib.getEpisodeProgressData(itemId, episodeId!)
          : lib.getProgressData(itemId);
      pos = (pd?['currentTime'] as num?)?.toDouble() ?? 0;
    }
    showChaptersSheet(
      context: ctx, accent: accent, tt: tt,
      chapters: chaps,
      totalDuration: isCastingThis ? cast.castingDuration : (isActive ? player.totalDuration : duration),
      currentPosition: pos,
      isPlaybackActive: isPlaybackActive,
      isCastingThis: isCastingThis,
      displaySpeed: speedAdjustedTime ? (isActive ? player.speed : savedSpeed) : 1.0,
      player: player,
      itemId: itemId,
    );
  }

  void showHistory(BuildContext ctx, Color accent, TextTheme tt) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false, initialChildSize: 0.6, minChildSize: 0.05, snap: true, maxChildSize: 0.9,
        builder: (_, sc) => _PlaybackHistoryBody(
          itemId: itemId,
          accent: accent,
          tt: tt,
          isActive: isActive,
          player: player,
          parentCtx: ctx,
          sheetCtx: sheetCtx,
          scrollController: sc,
        ),
      ),
    );
  }

  Future<void> _openDetails() async {
    if (episodeId != null || isPodcastEpisode) {
      final episode = await _resolveEpisode();
      if (context.mounted) EpisodeDetailSheet.show(context, item, episode);
    } else {
      showBookDetailSheet(context, itemId);
    }
  }

  Future<Map<String, dynamic>> _resolveEpisode() async {
    final epId = episodeId ?? player.currentEpisodeId;
    final episodes = _media['episodes'] as List<dynamic>? ?? [];
    for (final ep in episodes) {
      if (ep is Map<String, dynamic> && ep['id'] == epId) return ep;
    }
    final api = context.read<AuthProvider>().apiService;
    if (api != null) {
      final fullItem = await api.getLibraryItem(itemId);
      if (fullItem != null) {
        final media = fullItem['media'] as Map<String, dynamic>? ?? {};
        final eps = media['episodes'] as List<dynamic>? ?? [];
        for (final ep in eps) {
          if (ep is Map<String, dynamic> && ep['id'] == epId) return ep;
        }
      }
    }
    if (recentEpisode != null) return recentEpisode!;
    return {
      'id': epId,
      'title': player.currentEpisodeTitle,
      'duration': player.totalDuration,
    };
  }
}

const String _kAdvancedHistoryPrefKey = 'playback_history_advanced';

class _PlaybackHistoryBody extends StatefulWidget {
  final String itemId;
  final Color accent;
  final TextTheme tt;
  final bool isActive;
  final AudioPlayerService player;
  final BuildContext parentCtx;
  final BuildContext sheetCtx;
  final ScrollController scrollController;

  const _PlaybackHistoryBody({
    required this.itemId,
    required this.accent,
    required this.tt,
    required this.isActive,
    required this.player,
    required this.parentCtx,
    required this.sheetCtx,
    required this.scrollController,
  });

  @override
  State<_PlaybackHistoryBody> createState() => _PlaybackHistoryBodyState();
}

class _PlaybackHistoryBodyState extends State<_PlaybackHistoryBody> {
  bool _advanced = false;
  Future<List<PlaybackEvent>>? _future;

  @override
  void initState() {
    super.initState();
    _future = PlaybackHistoryService().getHistory(widget.itemId);
    ScopedPrefs.getBool(_kAdvancedHistoryPrefKey).then((v) {
      if (!mounted) return;
      setState(() => _advanced = v ?? false);
    });
  }

  Future<void> _toggleAdvanced() async {
    final next = !_advanced;
    setState(() => _advanced = next);
    await ScopedPrefs.setBool(_kAdvancedHistoryPrefKey, next);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(widget.parentCtx)!;
    final cs = Theme.of(widget.parentCtx).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(widget.parentCtx).bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: widget.accent.withValues(alpha: 0.2), width: 1)),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: cs.onSurface.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            const Spacer(),
            Text(
              l.playbackHistory,
              style: widget.tt.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, size: 20, color: cs.onSurfaceVariant),
              onPressed: () async {
                await PlaybackHistoryService().clearHistory(widget.itemId);
                if (widget.sheetCtx.mounted) Navigator.pop(widget.sheetCtx);
              },
              tooltip: l.clearHistoryTooltip,
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(children: [
            if (widget.isActive)
              Expanded(
                child: Text(
                  l.tapEventToJump,
                  style: widget.tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              const Spacer(),
            Text(
              'Show more',
              style: widget.tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            Transform.scale(
              scale: 0.8,
              child: Switch(
                value: _advanced,
                onChanged: (_) => _toggleAdvanced(),
                activeThumbColor: widget.accent,
              ),
            ),
          ]),
        ),
        Expanded(
          child: FutureBuilder<List<PlaybackEvent>>(
            future: _future,
            builder: (futureCtx, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }
              final all = snap.data!;
              final events = _advanced
                  ? all
                  : all.where((e) => !kAdvancedHistoryEvents.contains(e.type)).toList();
              if (events.isEmpty) {
                return Center(
                  child: Text(
                    l.noHistoryYet,
                    style: widget.tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                );
              }

              final items = <Widget>[];
              String? lastDate;
              for (int i = 0; i < events.length; i++) {
                final e = events[i];
                final dl = dateLabel(e.timestamp);
                if (dl != lastDate) {
                  lastDate = dl;
                  items.add(Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      dl,
                      style: widget.tt.labelSmall?.copyWith(
                        color: widget.accent.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ));
                }
                final posLabel = fmtTime(e.positionSeconds);
                final timeStr = timeOfDay(e.timestamp);
                final isAdvancedEvent = kAdvancedHistoryEvents.contains(e.type);
                items.add(ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  leading: Icon(
                    historyIcon(e.type),
                    size: 18,
                    color: widget.accent.withValues(alpha: isAdvancedEvent ? 0.45 : 0.7),
                  ),
                  title: Text(
                    e.label,
                    style: widget.tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: isAdvancedEvent ? 0.55 : 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    l.atPosition(posLabel),
                    style: widget.tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  trailing: Text(
                    timeStr,
                    style: widget.tt.labelSmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.3),
                    ),
                  ),
                  onTap: widget.isActive
                      ? () {
                          widget.player.seekTo(Duration(seconds: e.positionSeconds.round()));
                          Navigator.pop(futureCtx);
                          ScaffoldMessenger.of(widget.parentCtx).showSnackBar(
                            SnackBar(
                              duration: const Duration(seconds: 3),
                              content: Text(l.jumpedToPosition(posLabel)),
                            ),
                          );
                        }
                      : null,
                ));
              }

              return ListView(controller: widget.scrollController, children: items);
            },
          ),
        ),
      ]),
    );
  }
}
