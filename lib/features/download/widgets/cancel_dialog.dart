import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../download_task.dart';

/// Asks whether to cancel [task], since every destructive action in the
/// app asks first. Returns true only when the user confirms.
Future<bool> confirmCancel(BuildContext context, DownloadTask task) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _CancelDialog(task: task),
  );
  return confirmed ?? false;
}

/// "Cancel 第2卷?" with what cancelling means, then CANCEL DOWNLOAD over
/// KEEP.
///
/// The two buttons are stacked full width: side by side they need about
/// 280 dp, more than a 366 dp phone's dialog has, and Material's own
/// overflow stacks them at ragged widths.
class _CancelDialog extends StatelessWidget {
  const _CancelDialog({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final isRunning = task.status == DownloadStatus.downloading;
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.cancelTitle(task.title)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(isRunning ? l10n.cancelRunning : l10n.cancelWaiting),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.cancelDownload),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.keep),
          ),
        ],
      ),
    );
  }
}
