import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../l10n/l10n.dart';
import '../../models/download_record.dart';
import '../../models/result.dart';
import '../../models/volume.dart';
import '../../repositories/background_download_repository.dart';
import '../../repositories/downloaded_volume_repository.dart';
import '../../repositories/novel_repository.dart';
import '../../state/download_records_state.dart';
import '../../state/settings_state.dart';
import '../../utils/error_messages.dart';
import 'download_notice.dart';
import 'download_task.dart';

/// The Downloads tab's rows. It lives as long as the app, so downloads keep
/// going while the user browses.
final downloadQueueProvider =
    NotifierProvider<DownloadQueueController, List<DownloadTask>>(
      DownloadQueueController.new,
    );

/// How many volumes are waiting or downloading, for the Downloads tab badge.
final activeDownloadCountProvider = Provider<int>((ref) {
  return ref.watch(downloadQueueProvider).where((t) => t.isActive).length;
});

/// Downloads volumes one at a time, in the order they were added: packs
/// each into an EPUB, saves it to Download and records it. While any
/// volume waits or downloads, a notification shows the progress and keeps
/// the app running in the background.
class DownloadQueueController extends Notifier<List<DownloadTask>> {
  DownloadQueueController({
    this.gapBetweenVolumes = AppConfig.delayBetweenVolumes,
  });

  /// Pause before each volume after the first, to go easy on the site.
  final Duration gapBetweenVolumes;

  var _nextId = 0;
  var _isRunning = false;

  @override
  List<DownloadTask> build() {
    listenSelf((_, tasks) => _syncNotice(tasks));
    return const [];
  }

  /// Adds [volume] as a new row at the end. It starts at once if nothing
  /// else is downloading, otherwise it waits its turn.
  ///
  /// Returns false, adding nothing, when the volume is already waiting or
  /// downloading. A saved or failed row of the same volume is replaced, so
  /// each volume has one row.
  bool add(Volume volume, String bookTitle) => _addRow([volume], bookTitle);

  /// Adds [volumes], in book order, as one row that makes a single EPUB of
  /// them. Returns false, adding nothing, when any of them is already
  /// waiting or downloading; saved or failed rows of them are replaced.
  bool addMerged(List<Volume> volumes, String bookTitle) {
    return _addRow(volumes, bookTitle);
  }

  /// Adds one row for [volumes] unless one of them is already active.
  bool _addRow(List<Volume> volumes, String bookTitle) {
    bool overlaps(DownloadTask task) => volumes.any(task.includes);
    if (state.any((task) => task.isActive && overlaps(task))) return false;
    final task = DownloadTask(
      id: _nextId++,
      volumes: volumes,
      bookTitle: bookTitle,
    );
    state = [
      for (final old in state)
        if (!overlaps(old)) old,
      task,
    ];
    _runQueue();
    return true;
  }

  /// Puts a failed row back in line to download again.
  void retry(int id) {
    _update(id, (task) {
      return task.copyWith(status: DownloadStatus.waiting, chaptersDone: 0);
    });
    _runQueue();
  }

  /// Removes a waiting or downloading row. A running download notices
  /// before its next chapter or image and stops without saving. A row that
  /// finished meanwhile, such as while the confirmation was open, stays.
  void cancel(int id) {
    state = [
      for (final task in state)
        if (task.id != id || !task.isActive) task,
    ];
  }

  /// Opens the saved file of the row with [id] in a reader app. Returns
  /// Err with one sentence when it cannot, such as when the file is gone.
  Future<Result<void>> openSaved(int id) async {
    final uri = state.where((task) => task.id == id).firstOrNull?.fileUri;
    if (uri == null) return const Err(somethingWentWrong);
    return ref.read(downloadedVolumeRepositoryProvider).open(uri);
  }

  /// Removes saved rows from the list. Their files and records stay.
  void clearSaved() {
    state = [
      for (final task in state)
        if (task.status != DownloadStatus.done) task,
    ];
  }

  /// Downloads waiting rows one by one until none is left. Does nothing
  /// when a run is already going, since that run picks up new rows too.
  ///
  /// A row cancelled during the pause stops at the pack's first cancel
  /// check, before any chapter is fetched.
  Future<void> _runQueue() async {
    if (_isRunning) return;
    _isRunning = true;
    var isFirst = true;
    for (var task = _nextWaiting(); task != null; task = _nextWaiting()) {
      if (!isFirst) await Future<void>.delayed(gapBetweenVolumes);
      isFirst = false;
      await _download(task);
    }
    _isRunning = false;
  }

  /// The first row still waiting, or null, also once the queue is gone.
  DownloadTask? _nextWaiting() {
    if (!ref.mounted) return null;
    for (final task in state) {
      if (task.status == DownloadStatus.waiting) return task;
    }
    return null;
  }

  /// Packs one volume into an EPUB, updating its row after each chapter.
  Future<void> _download(DownloadTask task) async {
    if (!ref.mounted) return;
    _update(task.id, (t) => t.copyWith(status: DownloadStatus.downloading));
    final packed = await ref
        .read(novelRepositoryProvider)
        .packVolumes(
          task.volumes,
          onProgress: (done, total) => _update(task.id, (t) {
            return t.copyWith(
              status: DownloadStatus.downloading,
              chaptersDone: done,
              chaptersTotal: total,
            );
          }),
          isCancelled: () => !_isListed(task.id),
        );
    switch (packed) {
      case Err(:final message):
        _fail(task.id, message);
      case Ok(data: final file):
        await _save(task, file);
    }
  }

  /// Saves a packed EPUB into the library folder and records it. A row cancelled
  /// while its last chapter was packing is not saved.
  Future<void> _save(DownloadTask task, File file) async {
    if (!_isListed(task.id)) return;
    final repository = ref.read(downloadedVolumeRepositoryProvider);
    final folder = (await ref.read(settingsProvider.future)).libraryFolder;
    final saved = task.isMerged
        ? await repository.saveMerged(file, folderUri: folder)
        : await repository.save(
            file,
            bookId: task.volume.bookId,
            volumeNumber: task.volume.number,
            folderUri: folder,
          );
    switch (saved) {
      case Err(:final message):
        _fail(task.id, message);
      case Ok(data: final uri):
        await _record(task, uri);
        _update(task.id, (t) {
          return t.copyWith(status: DownloadStatus.done, fileUri: uri);
        });
    }
  }

  /// Writes one download record per volume of the row, all pointing at
  /// the saved file. The EPUB is already saved, so a record that cannot be
  /// stored is logged rather than failing the row.
  Future<void> _record(DownloadTask task, String uri) async {
    for (final volume in task.volumes) {
      if (!ref.mounted) return;
      final record = DownloadRecord(
        bookId: volume.bookId,
        volumeNumber: volume.number,
        bookTitle: task.bookTitle,
        volumeTitle: volume.title,
        fileUri: uri,
        downloadedAt: DateTime.now(),
      );
      final records = ref.read(downloadRecordsProvider.notifier);
      final added = await records.add(record);
      if (added is Err<void>) {
        developer.log('download record not stored: ${added.message}');
      }
    }
  }

  /// Marks a row failed with one readable sentence.
  void _fail(int id, String message) {
    _update(id, (task) {
      return task.copyWith(
        status: DownloadStatus.failed,
        errorMessage: message,
      );
    });
  }

  /// Shows the queue's progress in the background notice, or takes the
  /// notice away once nothing is waiting or downloading.
  void _syncNotice(List<DownloadTask> tasks) {
    final background = ref.read(backgroundDownloadRepositoryProvider);
    final language = ref.read(settingsProvider).value?.language;
    final l10n = lookupAppLocalizations(Locale(language?.code ?? 'en'));
    final notice = noticeFor(l10n, tasks);
    if (notice == null) {
      background.hide();
    } else {
      background.show(notice);
    }
  }

  /// True while the row with [id] is still on the list, that is, not
  /// cancelled and the queue still alive.
  bool _isListed(int id) {
    return ref.mounted && state.any((task) => task.id == id);
  }

  /// Replaces the row with [id] by what [change] makes of it.
  void _update(int id, DownloadTask Function(DownloadTask task) change) {
    if (!ref.mounted) return;
    state = [for (final task in state) task.id == id ? change(task) : task];
  }
}
