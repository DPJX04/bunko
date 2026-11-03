import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'motion.dart';

/// Shows one of [children] at a time and keeps the others alive, switching
/// with Material's fade through: the old page fades out quickly, then the
/// new one fades in while growing slightly.
///
/// Unlike a plain switcher it never rebuilds a hidden child, so a tab keeps
/// its scroll position, and the web view never reloads.
class FadeThroughStack extends StatefulWidget {
  const FadeThroughStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<FadeThroughStack> createState() => _FadeThroughStackState();
}

class _FadeThroughStackState extends State<FadeThroughStack>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, value: 1);
  late int _current = widget.index;
  int? _previous;

  @override
  void didUpdateWidget(FadeThroughStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index == _current) return;
    _previous = _current;
    _current = widget.index;
    _controller.duration = motionDuration(context, Motion.fadeThrough);
    _controller.forward(from: 0).whenCompleteOrCancel(_finishSwitch);
  }

  /// Drops the old tab from view once the fade through has ended.
  void _finishSwitch() {
    if (mounted && _controller.isCompleted) setState(() => _previous = null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < widget.children.length; i++)
          _layer(i, widget.children[i]),
      ],
    );
  }

  /// Wraps one child: animated while it enters or leaves, otherwise kept
  /// alive but hidden, silent to touch, screen readers and tickers.
  Widget _layer(int i, Widget child) {
    final isCurrent = i == _current;
    final isLeaving = i == _previous;
    return Visibility(
      visible: isCurrent || isLeaving,
      maintainState: true,
      child: TickerMode(
        enabled: isCurrent,
        child: IgnorePointer(
          ignoring: !isCurrent,
          child: ExcludeSemantics(
            excluding: !isCurrent,
            child: FadeThroughTransition(
              animation: isCurrent ? _controller : kAlwaysCompleteAnimation,
              secondaryAnimation: isLeaving
                  ? _controller
                  : kAlwaysDismissedAnimation,
              fillColor: Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
