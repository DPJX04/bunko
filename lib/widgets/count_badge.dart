import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'motion.dart';

/// A small neutral plate with a count, set on the top end of [child], such
/// as the number of volumes in the queue on the Downloads tab. It is hidden
/// at zero.
///
/// The plate takes the legend colour with ink digits, never red: a count is
/// news, not a failure, and colour in this world is only ever a line.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        PositionedDirectional(
          top: -6,
          start: 14,
          child: AnimatedSwitcher(
            duration: motionDuration(context, Motion.quick),
            child: count == 0
                ? const SizedBox.shrink()
                : _Plate(key: ValueKey(count), count: count),
          ),
        ),
      ],
    );
  }
}

/// The plate itself: at least 16 dp square, 2 dp corners, tabular digits.
class _Plate extends StatelessWidget {
  const _Plate({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final digits = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: scheme.surface,
      letterSpacing: 0,
      height: 1,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      label: context.l10n.queueCount(count),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.onSurface,
          borderRadius: const BorderRadius.all(Radius.circular(2)),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text('$count', style: digits),
            ),
          ),
        ),
      ),
    );
  }
}
