import 'dart:math' as dart_math;
import 'package:flutter/material.dart';

/// Reusable Absorb wave icon — the 5-bar ascending/descending wave pattern.
/// Used as the app logo on the login screen, stats session icon, etc.
/// For the animated nav bar version, see app_shell.dart's _AnimatedWaveIcon.
class AbsorbWaveIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AbsorbWaveIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return CustomPaint(
      size: Size(size, size),
      painter: _AbsorbWavePainter(color: c),
    );
  }
}

class _AbsorbWavePainter extends CustomPainter {
  final Color color;

  _AbsorbWavePainter({required this.color});

  static const _barHeights = [0.35, 0.6, 1.0, 0.6, 0.35];
  static const _barCount = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round;

    final totalWidth = size.width * 0.6;
    final startX = (size.width - totalWidth) / 2;
    final spacing = totalWidth / (_barCount - 1);
    final midY = size.height / 2;
    final maxHalf = size.height * 0.38;

    for (int i = 0; i < _barCount; i++) {
      final x = startX + spacing * i;
      final half = maxHalf * _barHeights[i];
      canvas.drawLine(Offset(x, midY - half), Offset(x, midY + half), paint);
    }
  }

  @override
  bool shouldRepaint(_AbsorbWavePainter old) => old.color != color;
}

/// The wave on a watch face, with the band stubs above and below - for a
/// session that came from the Wear OS app.
class AbsorbWatchIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AbsorbWatchIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return CustomPaint(
      size: Size(size, size),
      painter: _AbsorbWatchPainter(color: c),
    );
  }
}

class _AbsorbWatchPainter extends CustomPainter {
  final Color color;

  _AbsorbWatchPainter({required this.color});

  static const _barHeights = [0.35, 0.6, 1.0, 0.6, 0.35];
  static const _barCount = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, size.height / 2);
    final strokeW = s * 0.07;

    // The band: two rounded stubs the face sits between.
    final bandPaint = Paint()..color = color;
    final bandW = s * 0.34;
    final bandH = s * 0.13;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, s * 0.10), width: bandW, height: bandH),
        Radius.circular(bandH / 2),
      ),
      bandPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(center.dx, s * 0.90), width: bandW, height: bandH),
        Radius.circular(bandH / 2),
      ),
      bandPaint,
    );

    // The round face.
    final facePaint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, s * 0.33, facePaint);

    // The wave, small enough to sit inside the face.
    final barPaint = Paint()
      ..color = color
      ..strokeWidth = strokeW * 0.8
      ..strokeCap = StrokeCap.round;
    final totalWidth = s * 0.34;
    final startX = (s - totalWidth) / 2;
    final spacing = totalWidth / (_barCount - 1);
    final maxHalf = s * 0.19;
    for (int i = 0; i < _barCount; i++) {
      final x = startX + spacing * i;
      final half = maxHalf * _barHeights[i];
      canvas.drawLine(Offset(x, center.dy - half), Offset(x, center.dy + half), barPaint);
    }
  }

  @override
  bool shouldRepaint(_AbsorbWatchPainter old) => old.color != color;
}

/// Wave icon with a circular rewind arrow around it - for "Absorb Again".
class AbsorbReplayIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AbsorbReplayIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return CustomPaint(
      size: Size(size, size),
      painter: _AbsorbReplayPainter(color: c),
    );
  }
}

class _AbsorbReplayPainter extends CustomPainter {
  final Color color;

  _AbsorbReplayPainter({required this.color});

  static const _barHeights = [0.35, 0.6, 1.0, 0.6, 0.35];
  static const _barCount = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;
    final strokeW = size.width * 0.07;

    // Counter-clockwise arc with gap at top for arrowhead
    final arcPaint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const startAngle = -3.8; // gap on the left side
    const sweepAngle = -5.0; // sweep counter-clockwise ~286 degrees
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, startAngle, sweepAngle, false, arcPaint);

    // Arrowhead at the end of the arc, pointing counter-clockwise
    final endAngle = startAngle + sweepAngle;
    final arrowTip = Offset(
      center.dx + radius * cos(endAngle),
      center.dy + radius * sin(endAngle),
    );
    final arrowSize = size.width * 0.15;
    // Tangent direction for counter-clockwise travel (perpendicular to radius, reversed)
    final tangent = endAngle + dart_math.pi / 2;
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      arrowTip,
      Offset(
        arrowTip.dx + arrowSize * cos(tangent - 0.55),
        arrowTip.dy + arrowSize * sin(tangent - 0.55),
      ),
      arrowPaint,
    );
    canvas.drawLine(
      arrowTip,
      Offset(
        arrowTip.dx + arrowSize * cos(tangent + 0.55),
        arrowTip.dy + arrowSize * sin(tangent + 0.55),
      ),
      arrowPaint,
    );

    // Wave bars in the center (scaled down to fit inside the circle)
    final barPaint = Paint()
      ..color = color
      ..strokeWidth = strokeW * 0.85
      ..strokeCap = StrokeCap.round;

    final totalWidth = size.width * 0.42;
    final startX = (size.width - totalWidth) / 2;
    final spacing = totalWidth / (_barCount - 1);
    final midY = size.height / 2;
    final maxHalf = size.height * 0.26;

    for (int i = 0; i < _barCount; i++) {
      final x = startX + spacing * i;
      final half = maxHalf * _barHeights[i];
      canvas.drawLine(Offset(x, midY - half), Offset(x, midY + half), barPaint);
    }
  }

  static double cos(double radians) => _cos(radians);
  static double sin(double radians) => _sin(radians);
  static double _cos(double r) => dart_math.cos(r);
  static double _sin(double r) => dart_math.sin(r);

  @override
  bool shouldRepaint(_AbsorbReplayPainter old) => old.color != color;
}
