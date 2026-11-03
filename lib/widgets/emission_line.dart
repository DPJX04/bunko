import 'package:flutter/material.dart';

import 'motion.dart';
import 'spectrum.dart';

/// A 2 dp emission line drawn from the left edge to [fraction] of its
/// width, over a hairline track. Changes in length and colour glide over
/// 250 ms, or cut at once when Remove animations is on.
///
/// On the black plate the line glows; on bone it stays flat.
class EmissionLine extends StatelessWidget {
  const EmissionLine({
    super.key,
    required this.fraction,
    required this.color,
    this.showTrack = true,
  });

  /// How much of the width is lit, from 0 to 1.
  final double fraction;
  final Color color;

  /// Draws the unlit rest of the width as a hairline.
  final bool showTrack;

  @override
  Widget build(BuildContext context) {
    final duration = motionDuration(context, Motion.standard);
    final track = Theme.of(context).colorScheme.outlineVariant;
    final glow = Spectrum.of(context).glow;
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: color),
      duration: duration,
      builder: (context, lineColor, _) => TweenAnimationBuilder<double>(
        tween: Tween(end: fraction.clamp(0, 1)),
        duration: duration,
        curve: Motion.move,
        builder: (context, length, _) => SizedBox(
          height: 6,
          width: double.infinity,
          child: CustomPaint(
            painter: _LinePainter(
              length: length,
              color: lineColor ?? color,
              track: showTrack ? track : null,
              glow: glow,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the track hairline, then the lit part with its glow.
class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.length,
    required this.color,
    required this.track,
    required this.glow,
  });

  final double length;
  final Color color;
  final Color? track;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final trackColor = track;
    if (trackColor != null) {
      final hairline = Paint()
        ..color = trackColor
        ..strokeWidth = 0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), hairline);
    }
    final end = size.width * length;
    if (end <= 0) return;
    final lit = Rect.fromLTRB(0, y - 1, end, y + 1);
    if (glow > 0) {
      final halo = Paint()
        ..color = color.withValues(alpha: 0.5 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawRect(lit.inflate(1), halo);
    }
    canvas.drawRect(lit, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_LinePainter oldDelegate) {
    return oldDelegate.length != length ||
        oldDelegate.color != color ||
        oldDelegate.track != track ||
        oldDelegate.glow != glow;
  }
}
