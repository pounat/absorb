import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/api_service.dart';
import '../services/clip_editor_controller.dart';
import '../services/clip_export_service.dart';
import 'overlay_toast.dart';

/// Play-and-mark clip editor. Opened from the bookmark sheet's "Export clip".
/// Plays a navigable window around the bookmark; the user marks in/out by ear
/// (Set start / Set end at the playhead), fine-tunes with -1/+1, then saves an
/// .m4a to Files.
class ClipEditorSheet extends StatefulWidget {
  final String itemId;
  final double bookmarkSeconds;
  final String bookmarkTitle;
  final ApiService? api;
  const ClipEditorSheet({
    super.key,
    required this.itemId,
    required this.bookmarkSeconds,
    required this.bookmarkTitle,
    this.api,
  });

  @override
  State<ClipEditorSheet> createState() => _ClipEditorSheetState();
}

class _ClipEditorSheetState extends State<ClipEditorSheet> {
  late final ClipEditorController _c;
  bool _saving = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _c = ClipEditorController(
      itemId: widget.itemId,
      bookmarkSeconds: widget.bookmarkSeconds,
      api: widget.api,
    )..addListener(_onChange);
    _c.init().catchError((_) {
      if (mounted) setState(() => _failed = true);
    });
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.removeListener(_onChange);
    _c.dispose();
    super.dispose();
  }

  String _fmt(double s) {
    final v = s < 0 ? 0 : s.toInt();
    final h = v ~/ 3600;
    final m = (v % 3600) ~/ 60;
    final sec = v % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '$m:${sec.toString().padLeft(2, '0')}';
  }

  String _fileName() {
    final t = widget.bookmarkTitle.trim();
    final stamp = _fmt(_c.inPoint).replaceAll(':', '-');
    final safe =
        '${t.isEmpty ? 'Clip' : t} $stamp'.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return '${safe.isEmpty ? 'clip' : safe}.m4a';
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final res = await ClipExportService().exportClip(
        itemId: widget.itemId,
        startSeconds: _c.inPoint,
        requestedDuration: _c.clipDuration,
        api: widget.api,
      );
      final bytes = await File(res.tempPath).readAsBytes();
      final name = _fileName();
      final saved = await FilePicker.platform.saveFile(
        dialogTitle: l.clipExport,
        fileName: name,
        bytes: Uint8List.fromList(bytes),
      );
      try {
        await File(res.tempPath).delete();
      } catch (_) {}
      if (!mounted) return;
      if (saved == null) {
        setState(() => _saving = false);
        return; // user cancelled the save dialog
      }
      // Insert into the root overlay while this sheet's context is still
      // mounted, then close the sheet. The overlay entry survives the pop.
      showOverlayToast(
        context,
        res.clamped ? l.clipExportClamped : l.clipExportSaved(name),
        icon: Icons.content_cut_rounded,
      );
      navigator.pop();
    } catch (e) {
      debugPrint('[ClipEditor] save failed: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      // Show the reason in a dialog rather than a SnackBar: the editor is a
      // bottom sheet, and on iPad a SnackBar shown from within it hides behind
      // the sheet, so a failure looked like "nothing happened".
      final detail = e is ClipExportException ? e.message : e.toString();
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.clipExportFailed),
          content: Text(detail),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    // Clear the keyboard when it's open, otherwise the system navigation bar
    // (3-button mode) so the buttons aren't hidden behind it.
    final bottomInset = mq.viewInsets.bottom > mq.viewPadding.bottom
        ? mq.viewInsets.bottom
        : mq.viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: 20 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l.clipExport, style: tt.titleLarge),
              const Spacer(),
              if (_c.isReady)
                Text(
                  _fmt(_c.clipDuration),
                  style: tt.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_failed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text(l.bookmarkPreviewFailed)),
            )
          else if (!_c.isReady)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ..._editor(l, tt, cs),
        ],
      ),
    );
  }

  List<Widget> _editor(AppLocalizations l, TextTheme tt, ColorScheme cs) {
    final busy = _saving;
    return [
      _ClipScrubBar(
        windowStart: _c.windowStart,
        windowEnd: _c.windowEnd,
        inPoint: _c.inPoint,
        outPoint: _c.outPoint,
        position: _c.position,
        trackColor: cs.surfaceContainerHighest,
        selectionColor: cs.primary.withValues(alpha: 0.35),
        playheadColor: cs.primary,
        onSeek: busy ? null : _c.seekToGlobal,
      ),
      const SizedBox(height: 4),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_fmt(_c.windowStart), style: tt.bodySmall),
          Text(_fmt(_c.position),
              style: tt.bodySmall?.copyWith(
                fontFeatures: [const FontFeature.tabularFigures()],
              )),
          Text(_fmt(_c.windowEnd), style: tt.bodySmall),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            iconSize: 26,
            icon: const Icon(Icons.skip_previous_rounded),
            tooltip: l.clipJumpToStart,
            onPressed: busy ? null : () => _c.seekToGlobal(_c.inPoint),
          ),
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.replay_5_rounded),
            onPressed: busy ? null : () => _c.skip(-5),
          ),
          IconButton.filled(
            iconSize: 38,
            icon: Icon(_c.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            onPressed: busy ? null : _c.togglePlay,
          ),
          IconButton(
            iconSize: 28,
            icon: const Icon(Icons.forward_5_rounded),
            onPressed: busy ? null : () => _c.skip(5),
          ),
          IconButton(
            iconSize: 26,
            icon: const Icon(Icons.skip_next_rounded),
            tooltip: l.clipJumpToEnd,
            onPressed: busy ? null : () => _c.seekToGlobal(_c.outPoint),
          ),
        ],
      ),
      Center(
        child: TextButton.icon(
          icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
          label: const Text('Preview ending'),
          onPressed: busy ? null : () => _c.previewEnd(),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.first_page_rounded, size: 18),
              label: Text(l.clipSetStart),
              onPressed: busy ? null : () => setState(_c.setStart),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.last_page_rounded, size: 18),
              label: Text(l.clipSetEnd),
              onPressed: busy ? null : () => setState(_c.setEnd),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _markStepper(l.clipInLabel, _fmt(_c.inPoint), busy,
          () => _c.nudgeStart(-1), () => _c.nudgeStart(1)),
      const SizedBox(height: 12),
      _markStepper(l.clipOutLabel, _fmt(_c.outPoint), busy,
          () => _c.nudgeEnd(-1), () => _c.nudgeEnd(1)),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: _saving
              ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_alt_rounded),
          label: Text(l.clipSave),
          onPressed: (_saving || _c.clipDuration < ClipEditorController.minClip)
              ? null
              : _save,
        ),
      ),
    ];
  }

  // A spaced stepper for one clip end: label on the left, then -1 / time / +1
  // as icon buttons matching the transport controls.
  Widget _markStepper(String label, String value, bool busy,
      VoidCallback onMinus, VoidCallback onPlus) {
    final tt = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(label, style: tt.titleMedium),
        const Spacer(),
        IconButton(
          iconSize: 28,
          icon: const Icon(Icons.remove_circle_outline_rounded),
          onPressed: busy ? null : onMinus,
        ),
        SizedBox(
          width: 88,
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton(
          iconSize: 28,
          icon: const Icon(Icons.add_circle_outline_rounded),
          onPressed: busy ? null : onPlus,
        ),
      ],
    );
  }
}

/// A flat scrub bar: a track, a highlighted selection between in/out, and a
/// playhead. Tap or drag to move the playhead.
class _ClipScrubBar extends StatelessWidget {
  const _ClipScrubBar({
    required this.windowStart,
    required this.windowEnd,
    required this.inPoint,
    required this.outPoint,
    required this.position,
    required this.trackColor,
    required this.selectionColor,
    required this.playheadColor,
    required this.onSeek,
  });

  final double windowStart;
  final double windowEnd;
  final double inPoint;
  final double outPoint;
  final double position;
  final Color trackColor;
  final Color selectionColor;
  final Color playheadColor;
  final ValueChanged<double>? onSeek;

  double get _span => (windowEnd - windowStart).clamp(0.001, double.infinity);
  double _frac(double v) => ((v - windowStart) / _span).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      void seekAt(double dx) {
        if (onSeek == null) return;
        final frac = (dx / width).clamp(0.0, 1.0);
        onSeek!(windowStart + frac * _span);
      }

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => seekAt(d.localPosition.dx),
        onHorizontalDragUpdate: (d) => seekAt(d.localPosition.dx),
        child: SizedBox(
          height: 36,
          width: double.infinity,
          child: CustomPaint(
            painter: _ScrubPainter(
              startFrac: _frac(inPoint),
              endFrac: _frac(outPoint),
              posFrac: _frac(position),
              trackColor: trackColor,
              selectionColor: selectionColor,
              playheadColor: playheadColor,
            ),
          ),
        ),
      );
    });
  }
}

class _ScrubPainter extends CustomPainter {
  _ScrubPainter({
    required this.startFrac,
    required this.endFrac,
    required this.posFrac,
    required this.trackColor,
    required this.selectionColor,
    required this.playheadColor,
  });

  final double startFrac;
  final double endFrac;
  final double posFrac;
  final Color trackColor;
  final Color selectionColor;
  final Color playheadColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final track = Paint()..color = trackColor;
    canvas.drawRRect(
      RRect.fromLTRBR(0, cy - 3, size.width, cy + 3, const Radius.circular(3)),
      track,
    );
    final x1 = startFrac * size.width;
    final x2 = endFrac * size.width;
    canvas.drawRRect(
      RRect.fromLTRBR(x1, cy - 6, x2, cy + 6, const Radius.circular(4)),
      Paint()..color = selectionColor,
    );
    final px = (posFrac * size.width).clamp(0.0, size.width);
    final head = Paint()
      ..color = playheadColor
      ..strokeWidth = 2;
    canvas.drawLine(Offset(px, cy - 12), Offset(px, cy + 12), head);
    canvas.drawCircle(Offset(px, cy), 6, Paint()..color = playheadColor);
  }

  @override
  bool shouldRepaint(_ScrubPainter old) =>
      old.startFrac != startFrac ||
      old.endFrac != endFrac ||
      old.posFrac != posFrac ||
      old.selectionColor != selectionColor;
}
