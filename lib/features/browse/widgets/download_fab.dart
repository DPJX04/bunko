import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../widgets/emission_tick_border.dart';
import '../../../widgets/motion.dart';
import '../../../widgets/spectrum.dart';

/// The Download button for book pages: a plate with a hairline edge and a
/// cyan tick that folds smoothly to its icon while the page scrolls down.
/// Like every control, its outline turns dashed while pressed.
class DownloadFab extends StatefulWidget {
  const DownloadFab({
    super.key,
    required this.isExpanded,
    required this.onPressed,
  });

  final bool isExpanded;
  final VoidCallback onPressed;

  @override
  State<DownloadFab> createState() => _DownloadFabState();
}

class _DownloadFabState extends State<DownloadFab> {
  bool _pressed = false;

  /// Records whether a finger is down on the button.
  void _setPressed(bool pressed) {
    if (pressed != _pressed) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shape = EmissionTickBorder(
      tickColor: Spectrum.of(context).cyan,
      side: BorderSide(color: colors.outline, width: 1),
      dashed: _pressed,
    );
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: widget.isExpanded ? 1 : 0),
        duration: motionDuration(context, Motion.standard),
        curve: Motion.move,
        builder: (context, t, _) => FloatingActionButton.extended(
          onPressed: widget.onPressed,
          tooltip: context.l10n.downloadVolumesTooltip,
          shape: shape,
          extendedPadding: EdgeInsetsDirectional.only(
            start: 16 + 6 * t,
            end: 16 + 4 * t,
          ),
          extendedIconLabelSpacing: 10 * t,
          icon: const Icon(Icons.download_rounded),
          label: ClipRect(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: t,
              child: Opacity(opacity: t, child: Text(context.l10n.download)),
            ),
          ),
        ),
      ),
    );
  }
}
