import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'emission_line.dart';
import 'emission_tick_border.dart';
import 'spectrum.dart';

/// Shows what went wrong in one sentence under a short red line, the
/// world's mark for failed, with a RETRY button.
///
/// It is only as tall as its content; the caller centres and pads it, so
/// it fits a sheet as well as a full screen.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          child: EmissionLine(
            fraction: 1,
            color: Spectrum.of(context).red,
            showTrack: false,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          localizedError(context.l10n, message),
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // Retry is a neutral action, so it carries the ash tick.
        FilledButton(
          onPressed: onRetry,
          style: ButtonStyle(
            shape: tickShape(
              tick: colors.onSurfaceVariant,
              outline: colors.outline,
            ),
          ),
          child: Text(context.l10n.retry),
        ),
      ],
    );
  }
}
