import 'package:flutter/material.dart';

import 'emission_tick_border.dart';

/// A calm empty screen: a picture, one heading, one sentence that teaches
/// what will appear here, and the one action that gets there.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.art,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.actionTick,
  });

  final Widget art;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  /// The action's tick colour, such as the wavelength of the tab it opens.
  /// Null keeps the theme's tick.
  final Color? actionTick;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              art,
              const SizedBox(height: 32),
              Text(title, style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                message,
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onAction,
                style: _actionStyle(context),
                child: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Swaps only the tick colour when [actionTick] is set.
  ButtonStyle? _actionStyle(BuildContext context) {
    final tick = actionTick;
    if (tick == null) return null;
    final outline = Theme.of(context).colorScheme.outline;
    return ButtonStyle(
      shape: tickShape(tick: tick, outline: outline),
    );
  }
}
