import 'package:flutter/material.dart';

/// A near-square plate outline with a short coloured tick just inside its
/// leading edge: the mark every control carries in this world. While the
/// control is pressed, its hairline outline turns dashed.
@immutable
class EmissionTickBorder extends OutlinedBorder {
  const EmissionTickBorder({
    required this.tickColor,
    super.side,
    this.radius = 2,
    this.dashed = false,
  });

  final Color tickColor;
  final double radius;

  /// True while pressed: the outline is drawn as a dashed hairline.
  final bool dashed;

  /// Distance from the leading edge to the tick, in logical pixels.
  static const _inset = 10.0;

  /// Dash and gap length of the pressed outline, in logical pixels.
  static const _dash = 4.0;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  /// The rounded rectangle every path and paint call starts from.
  RRect _plate(Rect rect) {
    return RRect.fromRectAndRadius(rect, Radius.circular(radius));
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(_plate(rect).deflate(side.strokeInset));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRRect(_plate(rect));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style != BorderStyle.none) _paintOutline(canvas, rect);
    final height = rect.height * 0.36;
    final tick = Rect.fromLTWH(
      rect.left + _inset,
      rect.center.dy - height / 2,
      2,
      height,
    );
    canvas.drawRect(tick, Paint()..color = tickColor);
  }

  /// Draws the hairline outline, solid at rest and dashed when pressed.
  void _paintOutline(Canvas canvas, Rect rect) {
    final outline = Path()
      ..addRRect(_plate(rect).deflate(side.strokeInset / 2));
    if (!dashed) {
      canvas.drawPath(outline, side.toPaint());
      return;
    }
    for (final metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash * 2) {
        canvas.drawPath(metric.extractPath(d, d + _dash), side.toPaint());
      }
    }
  }

  @override
  EmissionTickBorder copyWith({BorderSide? side, Color? tickColor}) {
    return EmissionTickBorder(
      tickColor: tickColor ?? this.tickColor,
      side: side ?? this.side,
      radius: radius,
      dashed: dashed,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return EmissionTickBorder(
      tickColor: tickColor,
      side: side.scale(t),
      radius: radius * t,
      dashed: dashed,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EmissionTickBorder &&
        other.tickColor == tickColor &&
        other.side == side &&
        other.radius == radius &&
        other.dashed == dashed;
  }

  @override
  int get hashCode => Object.hash(tickColor, side, radius, dashed);
}

/// The control shape for a button style: a hairline plate in [outline]
/// with a [tick] on its leading edge, dashed while pressed.
WidgetStateProperty<OutlinedBorder> tickShape({
  required Color tick,
  required Color outline,
}) {
  return WidgetStateProperty.resolveWith((states) {
    return EmissionTickBorder(
      tickColor: states.contains(WidgetState.disabled)
          ? outline.withValues(alpha: 0.4)
          : tick,
      side: BorderSide(color: outline, width: 1),
      dashed: states.contains(WidgetState.pressed),
    );
  });
}
