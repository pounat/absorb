import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'overlay_toast.dart';

/// Where a tap on the page goes: a 3x3 grid whose lines can be moved, each
/// square turning a page, showing the controls or doing nothing. App-wide,
/// like the rest of how the reader is held.
class ReaderTapZones {
  const ReaderTapZones({
    this.xs = const [0.25, 0.75],
    this.ys = const [1 / 3, 2 / 3],
    this.cells = const ['prev', 'menu', 'next', 'prev', 'menu', 'next', 'prev', 'menu', 'next'],
  });

  /// The two lines down the page and the two across it, as fractions.
  final List<double> xs;
  final List<double> ys;

  /// What each square does, row by row: 'prev', 'next', 'menu' or 'none'.
  final List<String> cells;

  static const actions = ['prev', 'next', 'menu', 'none'];
  static const minCell = 0.1;
  static const _kGrid = 'ereader_tap_grid';

  /// Layouts to start from, after Moon+ Reader's.
  static const presets = [
    ReaderTapZones(),
    ReaderTapZones(
      ys: [0.3, 0.6],
      cells: ['prev', 'prev', 'prev', 'next', 'menu', 'next', 'next', 'next', 'next'],
    ),
    ReaderTapZones(
      ys: [0.3, 0.6],
      cells: ['prev', 'prev', 'prev', 'prev', 'menu', 'next', 'prev', 'next', 'next'],
    ),
    ReaderTapZones(
      ys: [0.4, 0.6],
      cells: ['prev', 'prev', 'prev', 'prev', 'menu', 'next', 'next', 'next', 'next'],
    ),
  ];

  String actionAt(double fx, double fy) {
    final c = fx < xs[0] ? 0 : (fx < xs[1] ? 1 : 2);
    final r = fy < ys[0] ? 0 : (fy < ys[1] ? 1 : 2);
    return cells[r * 3 + c];
  }

  bool sameAs(ReaderTapZones o) =>
      listEquals(cells, o.cells) &&
      (xs[0] - o.xs[0]).abs() < 0.005 &&
      (xs[1] - o.xs[1]).abs() < 0.005 &&
      (ys[0] - o.ys[0]).abs() < 0.005 &&
      (ys[1] - o.ys[1]).abs() < 0.005;

  ReaderTapZones copyWith({List<double>? xs, List<double>? ys, List<String>? cells}) =>
      ReaderTapZones(xs: xs ?? this.xs, ys: ys ?? this.ys, cells: cells ?? this.cells);

  static Future<ReaderTapZones> load() async {
    final raw = (await SharedPreferences.getInstance()).getString(_kGrid);
    if (raw == null) return const ReaderTapZones();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final xs = [for (final v in j['xs'] as List) (v as num).toDouble()];
      final ys = [for (final v in j['ys'] as List) (v as num).toDouble()];
      final cells = [for (final v in j['cells'] as List) '$v'];
      if (xs.length != 2 || ys.length != 2 || cells.length != 9) return const ReaderTapZones();
      if (cells.any((c) => !actions.contains(c)) || !cells.contains('menu')) return const ReaderTapZones();
      return ReaderTapZones(xs: xs, ys: ys, cells: cells);
    } catch (_) {
      return const ReaderTapZones();
    }
  }

  Future<void> save() async => (await SharedPreferences.getInstance())
      .setString(_kGrid, jsonEncode({'xs': xs, 'ys': ys, 'cells': cells}));
}

String tapActionLabel(AppLocalizations l, String action) => switch (action) {
      'prev' => l.readerTapPrev,
      'next' => l.readerTapNext,
      'menu' => l.readerTapMenu,
      _ => l.readerTapNothing,
    };

// Fixed colors rather than the theme's, which can sit too close together
// to tell apart. Orange and blue also stay apart for most color blindness.
Color _tint(String action) => switch (action) {
      'prev' => const Color(0xFFF57C00),
      'next' => const Color(0xFF1E88E5),
      'menu' => const Color(0xFF8D8D8D),
      _ => const Color(0xFF263238),
    };

IconData _actionIcon(String action) => switch (action) {
      'prev' => Icons.arrow_back_rounded,
      'next' => Icons.arrow_forward_rounded,
      'menu' => Icons.menu_rounded,
      _ => Icons.block_rounded,
    };

/// Shows the tap grid over the page. Drag its lines to resize the squares,
/// tap a square to change what it does, or start from a layout.
class TapZonesEditor extends StatefulWidget {
  const TapZonesEditor({
    super.key,
    required this.zones,
    required this.onChanged,
    required this.onDone,
  });

  final ReaderTapZones zones;
  final ValueChanged<ReaderTapZones> onChanged;
  final VoidCallback onDone;

  @override
  State<TapZonesEditor> createState() => _TapZonesEditorState();
}

class _TapZonesEditorState extends State<TapZonesEditor> {
  late ReaderTapZones _zones = widget.zones;

  void _set(ReaderTapZones z) {
    setState(() => _zones = z);
    widget.onChanged(z);
  }

  void _cycle(int i) {
    final cells = List.of(_zones.cells);
    final now = cells[i];
    // One square always shows the controls, or there would be no way back.
    if (now == 'menu' && cells.where((c) => c == 'menu').length == 1) {
      showOverlayToast(context, AppLocalizations.of(context)!.readerTapKeepMenu, icon: Icons.touch_app_outlined);
      return;
    }
    cells[i] = ReaderTapZones.actions[(ReaderTapZones.actions.indexOf(now) + 1) % ReaderTapZones.actions.length];
    _set(_zones.copyWith(cells: cells));
  }

  void _moveLine(bool across, int i, double delta) {
    final lines = List.of(across ? _zones.ys : _zones.xs);
    const m = ReaderTapZones.minCell;
    final lo = i == 0 ? m : lines[0] + m;
    final hi = i == 0 ? lines[1] - m : 1 - m;
    lines[i] = (lines[i] + delta).clamp(lo, hi);
    _set(across ? _zones.copyWith(ys: lines) : _zones.copyWith(xs: lines));
  }

  Widget _grip(ColorScheme cs, {required bool across}) => Container(
        width: across ? 44 : 22,
        height: across ? 22 : 44,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(11),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
        ),
        child: RotatedBox(
          quarterTurns: across ? 1 : 0,
          child: Icon(Icons.drag_indicator_rounded, size: 18, color: cs.onSurface),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.4),
        child: LayoutBuilder(builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final xs = [0.0, _zones.xs[0] * w, _zones.xs[1] * w, w];
          final ys = [0.0, _zones.ys[0] * h, _zones.ys[1] * h, h];
          return Stack(
            children: [
              for (var r = 0; r < 3; r++)
                for (var c = 0; c < 3; c++)
                  Positioned(
                    left: xs[c],
                    top: ys[r],
                    width: xs[c + 1] - xs[c],
                    height: ys[r + 1] - ys[r],
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _cycle(r * 3 + c),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _tint(_zones.cells[r * 3 + c]).withValues(alpha: 0.7),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 0.5),
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_actionIcon(_zones.cells[r * 3 + c]), color: Colors.white, size: 22),
                            const SizedBox(height: 2),
                            Text(
                              tapActionLabel(l, _zones.cells[r * 3 + c]),
                              textAlign: TextAlign.center,
                              style: tt.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              for (var i = 0; i < 2; i++) ...[
                Positioned(
                  left: xs[i + 1] - 1,
                  top: 0,
                  bottom: 0,
                  width: 2,
                  child: IgnorePointer(child: ColoredBox(color: Colors.white.withValues(alpha: 0.9))),
                ),
                Positioned(
                  top: ys[i + 1] - 1,
                  left: 0,
                  right: 0,
                  height: 2,
                  child: IgnorePointer(child: ColoredBox(color: Colors.white.withValues(alpha: 0.9))),
                ),
                Positioned(
                  left: xs[i + 1] - 16,
                  top: (ys[1] + ys[2]) / 2 - 26,
                  width: 32,
                  height: 52,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (d) => _moveLine(false, i, d.delta.dx / w),
                    child: Center(child: _grip(cs, across: false)),
                  ),
                ),
                Positioned(
                  left: (xs[1] + xs[2]) / 2 - 26,
                  top: ys[i + 1] - 16,
                  width: 52,
                  height: 32,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (d) => _moveLine(true, i, d.delta.dy / h),
                    child: Center(child: _grip(cs, across: true)),
                  ),
                ),
              ],
              Positioned(
                left: 12,
                right: 12,
                bottom: 16,
                child: Material(
                  color: cs.surface,
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.readerTapZones, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(l.readerTapZonesHint, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (final preset in ReaderTapZones.presets)
                              Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () => _set(preset),
                                  child: _PresetThumb(preset, selected: _zones.sameAs(preset)),
                                ),
                              ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _set(const ReaderTapZones()),
                              child: Text(l.reset),
                            ),
                            FilledButton(onPressed: widget.onDone, child: Text(l.done)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

/// A small picture of a layout, colored by what each square does.
class _PresetThumb extends StatelessWidget {
  const _PresetThumb(this.zones, {required this.selected});

  final ReaderTapZones zones;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: selected ? cs.primary : cs.outlineVariant, width: selected ? 2.5 : 1),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(painter: _ThumbPainter(zones)),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.zones);

  final ReaderTapZones zones;

  @override
  void paint(Canvas canvas, Size size) {
    final xs = [0.0, zones.xs[0] * size.width, zones.xs[1] * size.width, size.width];
    final ys = [0.0, zones.ys[0] * size.height, zones.ys[1] * size.height, size.height];
    for (var r = 0; r < 3; r++) {
      for (var c = 0; c < 3; c++) {
        final rect = Rect.fromLTRB(xs[c], ys[r], xs[c + 1], ys[r + 1]);
        canvas.drawRect(rect, Paint()..color = _tint(zones.cells[r * 3 + c]));
      }
    }
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 1;
    for (final x in [xs[1], xs[2]]) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (final y in [ys[1], ys[2]]) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(_ThumbPainter old) => !old.zones.sameAs(zones);
}
