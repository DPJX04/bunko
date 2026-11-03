import 'dart:math';

import 'package:flutter/material.dart';

import 'spectrum.dart';

/// How a line on the plate is drawn; the form, not the colour, tells state.
enum LineForm {
  /// Full height and solid: running now.
  solid,

  /// Full height and dashed: waiting its turn.
  dashed,

  /// Half height: done and saved.
  half,

  /// Crossed through: failed.
  struck,

  /// Two parallel lines: the one line that outranks the rest.
  doubled,
}

/// One vertical line on a [SpectrumPlate].
class PlateLine {
  const PlateLine(this.position, this.color, this.form);

  /// Across the plate, from 0 at the left edge to 1 at the right.
  final double position;
  final Color color;
  final LineForm form;
}

/// A small glass plate on the lowest step, flat: a hairline frame, one
/// off-centre rail, and vertical emission lines in their state forms.
class SpectrumPlate extends StatelessWidget {
  const SpectrumPlate({
    super.key,
    required this.lines,
    this.size = const Size(240, 112),
  });

  final List<PlateLine> lines;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: CustomPaint(
        size: size,
        painter: _PlatePainter(
          lines: lines,
          ground: colors.surfaceContainerLowest,
          rule: colors.outline,
          glow: Spectrum.of(context).glow,
        ),
      ),
    );
  }
}

/// Paints the plate once; it only repaints when its inputs change.
class _PlatePainter extends CustomPainter {
  _PlatePainter({
    required this.lines,
    required this.ground,
    required this.rule,
    required this.glow,
  });

  final List<PlateLine> lines;
  final Color ground;
  final Color rule;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final plate = Offset.zero & size;
    canvas.drawRect(plate, Paint()..color = ground);
    final railX = size.width * 0.3;
    canvas.drawLine(
      Offset(railX, 0),
      Offset(railX, size.height),
      Paint()
        ..color = rule
        ..strokeWidth = 0,
    );
    for (final line in lines) {
      _paintLine(canvas, size, line);
    }
    canvas.drawRect(
      plate,
      Paint()
        ..color = rule
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0,
    );
  }

  /// Draws one line in its form, with a soft glow on the black plate.
  void _paintLine(Canvas canvas, Size size, PlateLine line) {
    final x = size.width * line.position;
    final top = line.form == LineForm.half ? size.height * 0.5 : 0.0;
    final paint = Paint()
      ..color = line.color
      ..strokeWidth = 1.5;
    if (glow > 0) {
      final halo = Paint()
        ..color = line.color.withValues(alpha: 0.35 * glow)
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawLine(Offset(x, top), Offset(x, size.height), halo);
    }
    switch (line.form) {
      case LineForm.dashed:
        for (var y = top; y < size.height; y += 8) {
          canvas.drawLine(
            Offset(x, y),
            Offset(x, min(y + 4, size.height)),
            paint,
          );
        }
      case LineForm.doubled:
        canvas.drawLine(Offset(x - 2, top), Offset(x - 2, size.height), paint);
        canvas.drawLine(Offset(x + 2, top), Offset(x + 2, size.height), paint);
      case LineForm.struck:
        canvas.drawLine(Offset(x, top), Offset(x, size.height), paint);
        final mid = size.height / 2;
        canvas.drawLine(Offset(x - 6, mid + 6), Offset(x + 6, mid - 6), paint);
      case LineForm.solid:
      case LineForm.half:
        canvas.drawLine(Offset(x, top), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_PlatePainter oldDelegate) {
    return oldDelegate.lines != lines ||
        oldDelegate.ground != ground ||
        oldDelegate.glow != glow;
  }
}
