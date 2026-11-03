import 'package:flutter/material.dart';

import '../../../widgets/emission_tick_border.dart';
import '../../../widgets/motion.dart';

/// A row of hairline plates, one per option, of which one is picked, such
/// as SYSTEM, LIGHT and DARK. The picked plate rises to the high step and
/// its legend and tick turn to the legend colour; the others stay on the
/// ground in ash. No spectral colour: a choice like this leads nowhere.
class PlateChoice<T> extends StatelessWidget {
  const PlateChoice({
    super.key,
    required this.options,
    required this.picked,
    required this.onPicked,
  });

  /// Each option's value and its label, in order.
  final List<(T, String)> options;
  final T picked;
  final ValueChanged<T> onPicked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, (value, label)) in options.indexed) ...[
          if (index > 0) const SizedBox(width: 8),
          Expanded(
            child: _Plate(
              label: label,
              isPicked: value == picked,
              onTap: () => onPicked(value),
            ),
          ),
        ],
      ],
    );
  }
}

/// One option: a 48 dp plate with the leading tick, read by TalkBack as
/// one of a group with the picked one selected.
class _Plate extends StatelessWidget {
  const _Plate({
    required this.label,
    required this.isPicked,
    required this.onTap,
  });

  final String label;
  final bool isPicked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = isPicked ? scheme.onSurface : scheme.onSurfaceVariant;
    return MergeSemantics(
      child: Semantics(
        selected: isPicked,
        inMutuallyExclusiveGroup: true,
        child: AnimatedContainer(
          duration: motionDuration(context, Motion.quick),
          curve: Motion.move,
          decoration: BoxDecoration(
            color: isPicked ? scheme.surfaceContainerHigh : Colors.transparent,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
          ),
          child: TextButton(
            onPressed: onTap,
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
              padding: const WidgetStatePropertyAll(
                EdgeInsetsDirectional.fromSTEB(20, 12, 10, 12),
              ),
              foregroundColor: WidgetStatePropertyAll(ink),
              shape: tickShape(
                tick: ink,
                outline: isPicked ? scheme.onSurfaceVariant : scheme.outline,
              ),
              side: WidgetStatePropertyAll(
                BorderSide(
                  color: isPicked ? scheme.onSurfaceVariant : scheme.outline,
                ),
              ),
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}
