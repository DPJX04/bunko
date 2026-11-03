import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// A hairline rail with one glowing tick over the selected slot, such as
/// the open tab. When the selection changes, the tick slides along the rail
/// and lands with one damped overshoot, taking on the new slot's colour.
class EmissionRail extends StatefulWidget {
  const EmissionRail({
    super.key,
    required this.selectedIndex,
    required this.colors,
    required this.railColor,
    this.glow = 1,
    this.height = 6,
  });

  /// Which slot the tick marks.
  final int selectedIndex;

  /// One emission colour per slot; the slot count is its length.
  final List<Color> colors;

  final Color railColor;

  /// 1 for glowing lines on black, 0 for flat lines on bone.
  final double glow;

  final double height;

  @override
  State<EmissionRail> createState() => _EmissionRailState();
}

class _EmissionRailState extends State<EmissionRail>
    with SingleTickerProviderStateMixin {
  /// A spring that overshoots once and settles in about 400 ms.
  static final _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 380,
    ratio: 0.62,
  );

  /// The tick's position in slots: 0 is the first slot, 1 the second.
  late final _position = AnimationController.unbounded(
    vsync: this,
    value: widget.selectedIndex.toDouble(),
  );

  @override
  void didUpdateWidget(EmissionRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = widget.selectedIndex.toDouble();
    if (target == _position.value) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _position.value = target;
      return;
    }
    final spring = SpringSimulation(
      _spring,
      _position.value,
      target,
      _position.velocity,
    );
    _position.animateWith(spring);
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _RailPainter(
            position: _position,
            colors: widget.colors,
            railColor: widget.railColor,
            glow: widget.glow,
          ),
        ),
      ),
    );
  }
}

/// Paints the one-pixel rail and the tick at the animated slot position.
class _RailPainter extends CustomPainter {
  _RailPainter({
    required this.position,
    required this.colors,
    required this.railColor,
    required this.glow,
  }) : super(repaint: position);

  final Animation<double> position;
  final List<Color> colors;
  final Color railColor;
  final double glow;

  /// Width of the tick, in logical pixels.
  static const _tickWidth = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final slotWidth = size.width / colors.length;
    final railY = size.height - 0.5;
    final rail = Paint()
      ..color = railColor
      ..strokeWidth = 0;
    canvas.drawLine(Offset(0, railY), Offset(size.width, railY), rail);

    final centre = (position.value + 0.5) * slotWidth;
    final color = _colorAt(position.value);
    final tick = Rect.fromCenter(
      center: Offset(centre, railY - 1),
      width: _tickWidth,
      height: 2,
    );
    if (glow > 0) {
      final halo = Paint()
        ..color = color.withValues(alpha: 0.55 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawRect(tick.inflate(1), halo);
    }
    canvas.drawRect(tick, Paint()..color = color);
  }

  /// Blends between the two slot colours the tick is travelling between.
  Color _colorAt(double value) {
    final last = colors.length - 1;
    final clamped = value.clamp(0, last).toDouble();
    final from = clamped.floor();
    final to = (from + 1).clamp(0, last);
    return Color.lerp(colors[from], colors[to], clamped - from)!;
  }

  @override
  bool shouldRepaint(_RailPainter oldDelegate) {
    return oldDelegate.colors != colors ||
        oldDelegate.railColor != railColor ||
        oldDelegate.glow != glow;
  }
}
