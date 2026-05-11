import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../services/download_service.dart';
import '../services/playback_history_service.dart';
import 'overlay_toast.dart';

String dateLabel(DateTime dt, [AppLocalizations? l]) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final date = DateTime(dt.year, dt.month, dt.day);
  if (date == today) return l?.absorbingSharedToday ?? 'Today';
  if (date == today.subtract(const Duration(days: 1))) return l?.absorbingSharedYesterday ?? 'Yesterday';
  if (now.difference(dt).inDays < 7) {
    if (l != null) {
      switch (dt.weekday) {
        case 1: return l.absorbingSharedMonday;
        case 2: return l.absorbingSharedTuesday;
        case 3: return l.absorbingSharedWednesday;
        case 4: return l.absorbingSharedThursday;
        case 5: return l.absorbingSharedFriday;
        case 6: return l.absorbingSharedSaturday;
        case 7: return l.absorbingSharedSunday;
      }
    }
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dt.weekday - 1];
  }
  return '${dt.month}/${dt.day}/${dt.year}';
}

String timeOfDay(DateTime dt, [AppLocalizations? l]) {
  final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final isAm = dt.hour < 12;
  final ampm = l != null
      ? (isAm ? l.absorbingSharedAm : l.absorbingSharedPm)
      : (isAm ? 'AM' : 'PM');
  return '$h:$m $ampm';
}

String fmtTime(double s) {
  if (s < 0) s = 0;
  final h = (s / 3600).floor(); final m = ((s % 3600) / 60).floor(); final sec = (s % 60).floor();
  if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
}

String fmtDur(double s) {
  final h = (s / 3600).floor(); final m = ((s % 3600) / 60).floor(); final sec = (s % 60).floor();
  if (h > 0) return '${h}h ${m}m';
  return '${m}m ${sec}s';
}

IconData historyIcon(PlaybackEventType type) {
  switch (type) {
    case PlaybackEventType.play: return Icons.play_arrow_rounded;
    case PlaybackEventType.pause: return Icons.pause_rounded;
    case PlaybackEventType.seek: return Icons.swap_horiz_rounded;
    case PlaybackEventType.syncLocal: return Icons.save_rounded;
    case PlaybackEventType.syncServer: return Icons.cloud_done_rounded;
    case PlaybackEventType.autoRewind: return Icons.replay_rounded;
    case PlaybackEventType.skipForward: return Icons.forward_30_rounded;
    case PlaybackEventType.skipBackward: return Icons.replay_10_rounded;
    case PlaybackEventType.speedChange: return Icons.speed_rounded;
    case PlaybackEventType.bookFinished: return Icons.flag_rounded;
    case PlaybackEventType.sessionStart: return Icons.fiber_manual_record_rounded;
    case PlaybackEventType.sessionEnd: return Icons.stop_circle_outlined;
    case PlaybackEventType.clickDebounce: return Icons.touch_app_rounded;
  }
}

class CoverPlaceholder extends StatelessWidget {
  final String? title;
  final String? author;
  const CoverPlaceholder({super.key, this.title, this.author});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasText = title != null && title!.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primaryContainer,
            cs.surfaceContainerHighest,
          ],
        ),
      ),
      child: hasText
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories_rounded, size: 28,
                      color: cs.onPrimaryContainer.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Flexible(
                    child: Text(title!, textAlign: TextAlign.center, maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            height: 1.2, color: cs.onPrimaryContainer)),
                  ),
                  if (author != null && author!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(author!, textAlign: TextAlign.center, maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11,
                              color: cs.onPrimaryContainer.withValues(alpha: 0.7))),
                    ),
                  ],
                ],
              ),
            )
          : Center(child: Icon(Icons.auto_stories_rounded, size: 48,
              color: cs.onPrimaryContainer.withValues(alpha: 0.3))),
    );
  }
}

/// Shows [child] with BoxFit.contain; when the image doesn't fill the square,
/// a blurred copy of the cover is drawn behind it to fill the empty sides.
/// Set [enabled] to false to skip the blur and just render [child] directly.
class BlurPaddedCover extends StatelessWidget {
  final Widget child;
  final Widget blurChild;
  final bool enabled;
  const BlurPaddedCover({super.key, required this.child, required this.blurChild, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred background fill
        SizedBox.expand(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24, tileMode: TileMode.clamp),
            child: blurChild,
          ),
        ),
        // Darkening scrim so the foreground cover pops
        Container(color: Colors.black.withValues(alpha: 0.15)),
        // Actual cover, contained (no crop)
        SizedBox.expand(child: child),
      ],
    );
  }
}

// ─── DOWNLOAD BUTTON WITH FILL BAR (wide card style) ────────

class DownloadWideButton extends StatefulWidget {
  final String itemId;
  final String? coverUrl;
  final String title;
  final String? author;
  final Color accent;
  const DownloadWideButton({super.key, required this.itemId, this.coverUrl, required this.title, this.author, required this.accent});
  @override State<DownloadWideButton> createState() => _DownloadWideButtonState();
}

class _DownloadWideButtonState extends State<DownloadWideButton> {
  final _dl = DownloadService();

  @override void initState() { super.initState(); _dl.addListener(_rebuild); }
  @override void dispose() { _dl.removeListener(_rebuild); super.dispose(); }
  void _rebuild() { if (mounted) setState(() {}); }

  @override Widget build(BuildContext context) {
    final downloading = _dl.isDownloading(widget.itemId);
    final downloaded = _dl.isDownloaded(widget.itemId);
    final progress = _dl.downloadProgress(widget.itemId);
    final l = AppLocalizations.of(context)!;

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
      color = widget.accent;
    } else {
      icon = Icons.download_outlined;
      label = l.download;
      color = Theme.of(context).colorScheme.onSurfaceVariant;
    }

    return GestureDetector(
      onTap: () => _handleTap(context),
      child: Container(
        height: 36,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: downloaded ? dlGreen.withValues(alpha: 0.06) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: downloaded ? dlGreen.withValues(alpha: 0.15) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08)),
        ),
        child: Stack(children: [
          if (downloading)
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          Center(child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          )),
        ]),
      ),
    );
  }

  void _handleTap(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final api = auth.apiService;
    if (api == null) return;
    final l = AppLocalizations.of(context)!;
    if (_dl.isDownloaded(widget.itemId)) {
      showDialog(context: context, builder: (ctx) => AlertDialog(
        title: Text(l.removeDownloadQuestion),
        content: Text(l.removeDownloadContent),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          TextButton(onPressed: () {
            _dl.deleteDownload(widget.itemId);
            Navigator.pop(ctx);
            showOverlayToast(context, l.downloadRemoved, icon: Icons.delete_outline_rounded);
          },
            child: Text(l.remove, style: const TextStyle(color: Colors.redAccent))),
        ],
      ));
    } else if (_dl.isDownloading(widget.itemId)) {
      _dl.cancelDownload(widget.itemId);
    } else {
      final error = await _dl.downloadItem(api: api, itemId: widget.itemId, title: widget.title, author: widget.author, coverUrl: widget.coverUrl, libraryId: context.read<LibraryProvider>().selectedLibraryId);
      if (error != null && context.mounted) {
        showOverlayToast(context, error, icon: Icons.error_outline_rounded);
      }
    }
  }
}

// ─── ABSORBING WAVE ANIMATION ────────────────────────────────

class AbsorbingWave extends StatefulWidget {
  final Color color;
  const AbsorbingWave({super.key, required this.color});
  @override State<AbsorbingWave> createState() => _AbsorbingWaveState();
}

class _AbsorbingWaveState extends State<AbsorbingWave> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return CustomPaint(
          size: const Size(24, 24),
          painter: _WavePainter(phase: _ctrl.value, color: widget.color),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  _WavePainter({required this.phase, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final midY = size.height / 2;
    final path = Path();
    final waveLength = size.width;
    path.moveTo(0, midY);
    for (double x = 0; x <= size.width; x += 0.5) {
      final y = midY + 6 * math.sin((x / waveLength * 2 * math.pi) + (phase * 2 * math.pi));
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.phase != phase;
}
