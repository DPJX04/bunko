import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/result.dart';
import '../download_queue_controller.dart';
import '../download_task.dart';
import 'snack_bars.dart';

/// Announces the volume just saved, on whichever tab is open, with an OPEN
/// button that opens it in a reader app. Wrap the app frame in it.
///
/// Only the latest save is announced. While the app is in the background
/// its snackbars cannot show, so one per volume would pile up and play in
/// turn on coming back.
class SavedSnackListener extends ConsumerWidget {
  const SavedSnackListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<List<DownloadTask>>(downloadQueueProvider, (before, now) {
      final saved = _newlySaved(before ?? const [], now);
      if (saved.isNotEmpty) _announce(context, ref, saved.last);
    });
    return child;
  }

  /// Rows that are saved in [now] but were not saved in [before].
  List<DownloadTask> _newlySaved(
    List<DownloadTask> before,
    List<DownloadTask> now,
  ) {
    final savedBefore = {
      for (final task in before)
        if (task.status == DownloadStatus.done) task.id,
    };
    return [
      for (final task in now)
        if (task.status == DownloadStatus.done &&
            !savedBefore.contains(task.id))
          task,
    ];
  }

  /// Shows "Saved 第2卷" with OPEN in place of any snackbar showing or
  /// waiting; a file that will not open says why.
  void _announce(BuildContext context, WidgetRef ref, DownloadTask task) {
    final messenger = ScaffoldMessenger.of(context);
    final queue = ref.read(downloadQueueProvider.notifier);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      savedSnackBar(
        volumeTitle: task.title,
        onOpen: () async {
          final opened = await queue.openSaved(task.id);
          if (opened is Err<void>) {
            messenger.showSnackBar(messageSnackBar(opened.message));
          }
        },
      ),
    );
  }
}
