import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../widgets/app_theme.dart';
import '../../../widgets/emission_tick_border.dart';
import '../../../widgets/spectrum.dart';

/// The snackbar shown after the picker adds volumes, such as "3 volumes
/// added", or "3 volumes added as one EPUB" when [isMerged], with a VIEW
/// button to the Downloads tab.
///
/// Snackbars are inverted plates, so their content uses the opposite
/// theme: an action is a hairline plate whose tick names where it leads,
/// at the strength that reads on that plate. VIEW carries the green of
/// Downloads.
SnackBar addedSnackBar({
  required int count,
  required VoidCallback onView,
  bool isMerged = false,
}) {
  return SnackBar(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 8, 6),
    margin: _aboveDownloadButton,
    content: _PlateMessage(
      text: (l10n) =>
          isMerged ? l10n.volumesAddedMerged(count) : l10n.volumesAdded(count),
      actionLabel: (l10n) => l10n.view,
      tick: (spectrum) => spectrum.green,
      onAction: onView,
    ),
  );
}

/// The snackbar shown when a volume is saved, on whichever tab is open:
/// "Saved 第2卷" with an OPEN button that opens it in a reader app. OPEN
/// carries the cyan of saved volumes.
SnackBar savedSnackBar({
  required String volumeTitle,
  required VoidCallback onOpen,
}) {
  return SnackBar(
    padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 8, 6),
    margin: _aboveDownloadButton,
    // Longer than the usual four seconds: it is the one-tap way to read.
    duration: const Duration(seconds: 6),
    content: _PlateMessage(
      text: (l10n) => l10n.savedVolume(volumeTitle),
      actionLabel: (l10n) => l10n.open,
      tick: (spectrum) => spectrum.cyan,
      onAction: onOpen,
    ),
  );
}

/// A snackbar that only says something, such as why a file did not open,
/// in the language picked in Settings.
SnackBar messageSnackBar(String message) {
  return SnackBar(
    margin: _aboveDownloadButton,
    content: Builder(
      builder: (context) => Text(localizedError(context.l10n, message)),
    ),
  );
}

/// Floats a snackbar just above the Download button on Browse (56 dp
/// tall, 16 dp off the bottom) instead of over it. The button belongs to
/// the Browse tab's own Scaffold, which the app's snackbars never see, so
/// they cannot make room for it themselves.
const _aboveDownloadButton = EdgeInsets.fromLTRB(16, 0, 16, 16 + 56 + 8);

/// One line of text and one action button, drawn in the inverse theme.
class _PlateMessage extends StatelessWidget {
  const _PlateMessage({
    required this.text,
    required this.actionLabel,
    required this.tick,
    required this.onAction,
  });

  /// The message and the action's label, in the picked language.
  final String Function(AppLocalizations l10n) text;
  final String Function(AppLocalizations l10n) actionLabel;

  /// Picks the action's tick from the inverse theme's lines.
  final Color Function(Spectrum spectrum) tick;
  final VoidCallback onAction;

  /// Hides the snackbar, then runs the action.
  void _act(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    onAction();
  }

  @override
  Widget build(BuildContext context) {
    final inverse = AppTheme.inverseOf(context);
    final l10n = context.l10n;
    return Theme(
      data: inverse,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Builder(
            builder: (context) => TextButton(
              onPressed: () => _act(context),
              style: ButtonStyle(
                shape: tickShape(
                  tick: tick(inverse.extension<Spectrum>()!),
                  outline: inverse.colorScheme.outline,
                ),
              ),
              child: Text(actionLabel(l10n)),
            ),
          ),
        ],
      ),
    );
  }
}
