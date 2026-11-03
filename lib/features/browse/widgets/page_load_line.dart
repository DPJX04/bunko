import 'package:flutter/material.dart';

import '../../../widgets/motion.dart';
import '../../../widgets/spectrum.dart';

/// The page-load line under the status strip: a doubled sodium hairline
/// that slides across as the page loads, lands at full width, then fades.
class PageLoadLine extends StatefulWidget {
  const PageLoadLine({
    super.key,
    required this.progress,
    required this.isLoading,
  });

  /// From 0 to 1.
  final double progress;
  final bool isLoading;

  @override
  State<PageLoadLine> createState() => _PageLoadLineState();
}

class _PageLoadLineState extends State<PageLoadLine>
    with TickerProviderStateMixin {
  late final _length = AnimationController(vsync: this, value: widget.progress);
  late final _opacity = AnimationController(
    vsync: this,
    value: widget.isLoading ? 1 : 0,
  );

  @override
  void didUpdateWidget(PageLoadLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading) {
      _showProgress();
    } else if (oldWidget.isLoading) {
      _landAndFade();
    }
  }

  /// Slides the line to the new progress; a new page starts it from zero.
  void _showProgress() {
    final duration = motionDuration(context, Motion.standard);
    if (widget.progress < _length.value) _length.value = widget.progress;
    _length.animateTo(widget.progress, duration: duration, curve: Motion.move);
    _opacity.animateTo(1, duration: motionDuration(context, Motion.quick));
  }

  /// Finishes the line at full width, then fades it away.
  Future<void> _landAndFade() async {
    final duration = motionDuration(context, Motion.standard);
    await _length.animateTo(1, duration: duration, curve: Motion.enter);
    if (!mounted) return;
    await _opacity.animateTo(0, duration: duration, curve: Motion.exit);
  }

  @override
  void dispose() {
    _length.dispose();
    _opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spectrum = Spectrum.of(context);
    return IgnorePointer(
      child: FadeTransition(
        opacity: _opacity,
        child: SizedBox(
          height: 6,
          width: double.infinity,
          child: CustomPaint(
            painter: _DoubledLinePainter(
              length: _length,
              color: spectrum.sodium,
              glow: spectrum.glow,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints two parallel hairlines from the left edge to the current length.
class _DoubledLinePainter extends CustomPainter {
  _DoubledLinePainter({
    required this.length,
    required this.color,
    required this.glow,
  }) : super(repaint: length);

  final Animation<double> length;
  final Color color;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final end = size.width * length.value;
    if (end <= 0) return;
    final line = Paint()
      ..color = color
      ..strokeWidth = 1;
    if (glow > 0) {
      final halo = Paint()
        ..color = color.withValues(alpha: 0.5 * glow)
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawLine(const Offset(0, 2.5), Offset(end, 2.5), halo);
    }
    canvas.drawLine(const Offset(0, 1), Offset(end, 1), line);
    canvas.drawLine(const Offset(0, 4), Offset(end, 4), line);
  }

  @override
  bool shouldRepaint(_DoubledLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.glow != glow;
  }
}
