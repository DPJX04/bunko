import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/motion.dart';
import '../../widgets/spectrum.dart';
import '../../widgets/spectrum_plate.dart';
import '../../models/result.dart';
import 'download_queue_controller.dart';
import 'download_task.dart';
import 'widgets/cancel_dialog.dart';
import 'widgets/download_task_tile.dart';
import 'widgets/snack_bars.dart';

/// The Downloads tab: one row per volume in the order added, each with a
/// percentage and one line. With nothing added it shows its empty state.
/// CLEAR in the app bar removes saved rows once there are any.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key, required this.onBrowse});

  /// Switches to the Browse tab.
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadQueueProvider);
    final queue = ref.read(downloadQueueProvider.notifier);
    final hasSaved = tasks.any((task) => task.status == DownloadStatus.done);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tabDownloads),
        actions: [_ClearAction(isShown: hasSaved, onClear: queue.clearSaved)],
      ),
      body: tasks.isEmpty
          ? _Empty(onBrowse: onBrowse)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: tasks.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => DownloadTaskTile(
                key: ValueKey(tasks[i].id),
                task: tasks[i],
                onRetry: () => queue.retry(tasks[i].id),
                onCancel: () => _cancel(context, queue, tasks[i]),
                onOpen: () => _open(context, queue, tasks[i]),
              ),
            ),
    );
  }

  /// Opens [task]'s saved file in a reader app, or says why it cannot.
  Future<void> _open(
    BuildContext context,
    DownloadQueueController queue,
    DownloadTask task,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final opened = await queue.openSaved(task.id);
    if (opened is Err<void>) {
      messenger.showSnackBar(messageSnackBar(opened.message));
    }
  }

  /// Cancels [task] once the user confirms in the dialog.
  Future<void> _cancel(
    BuildContext context,
    DownloadQueueController queue,
    DownloadTask task,
  ) async {
    if (await confirmCancel(context, task)) queue.cancel(task.id);
  }
}

/// CLEAR, fading in while saved rows exist. It removes them from the list
/// only; their files and records stay, so it needs no confirmation.
class _ClearAction extends StatelessWidget {
  const _ClearAction({required this.isShown, required this.onClear});

  final bool isShown;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: motionDuration(context, Motion.standard),
      child: isShown
          ? Padding(
              key: const ValueKey('clear'),
              // Lines the plate up with the rows' 24 dp gutter.
              padding: const EdgeInsetsDirectional.only(end: 24),
              child: Tooltip(
                message: context.l10n.clearTooltip,
                child: TextButton(
                  onPressed: onClear,
                  child: Text(context.l10n.clear),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// The empty state: a plate of solid green lines and the way to Browse.
class _Empty extends StatelessWidget {
  const _Empty({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final spectrum = Spectrum.of(context);
    final line = spectrum.green.withValues(alpha: 0.7);
    final l10n = context.l10n;
    return EmptyState(
      art: SpectrumPlate(
        lines: [
          PlateLine(0.48, line, LineForm.solid),
          PlateLine(0.64, line, LineForm.solid),
          PlateLine(0.82, line, LineForm.solid),
        ],
      ),
      title: l10n.downloadsEmptyTitle,
      message: l10n.downloadsEmptyMessage,
      actionLabel: l10n.browseBooks,
      actionTick: spectrum.violet,
      onAction: onBrowse,
    );
  }
}
