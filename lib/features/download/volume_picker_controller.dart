import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/book.dart';
import '../../models/result.dart';
import '../../repositories/novel_repository.dart';
import '../../state/download_records_state.dart';
import '../../state/settings_state.dart';
import 'download_queue_controller.dart';

/// What the volume picker shows: loading, a failure, or the book's volumes.
sealed class PickerState {
  const PickerState();
}

/// The table of contents is on its way.
final class PickerLoading extends PickerState {
  const PickerLoading();
}

/// The table of contents could not be loaded; [message] says why.
final class PickerFailed extends PickerState {
  const PickerFailed(this.message);

  final String message;
}

/// The book's volumes with their ticks and marks, each volume named by its
/// number in the table of contents, from 1.
final class PickerReady extends PickerState {
  const PickerReady(
    this.book, {
    this.ticked = const {},
    this.saved = const {},
    this.inDownloads = const {},
  });

  final Book book;

  /// Volumes ticked to download.
  final Set<int> ticked;

  /// Volumes downloaded before, marked SAVED. They can be ticked again.
  final Set<int> saved;

  /// Volumes waiting or downloading already, marked IN DOWNLOADS. They
  /// cannot be ticked.
  final Set<int> inDownloads;

  /// Volumes that can be ticked: every one not in Downloads.
  Set<int> get tickable {
    return {
      for (final volume in book.volumes)
        if (!inDownloads.contains(volume.number)) volume.number,
    };
  }

  /// True when every volume that can be ticked is ticked.
  bool get allTicked {
    final canTick = tickable;
    return canTick.isNotEmpty && ticked.containsAll(canTick);
  }

  /// The same volumes and marks with [ticked] as the ticks.
  PickerReady withTicks(Set<int> ticked) {
    return PickerReady(
      book,
      ticked: ticked,
      saved: saved,
      inDownloads: inDownloads,
    );
  }
}

/// The picker for one book id, such as '5330'. It is dropped when the
/// sheet closes, so opening the sheet again loads fresh contents.
final volumePickerProvider = NotifierProvider.autoDispose
    .family<VolumePickerController, PickerState, String>(
      VolumePickerController.new,
    );

/// Loads a book's table of contents and holds the volumes the user ticks.
class VolumePickerController extends Notifier<PickerState> {
  VolumePickerController(this.bookId);

  final String bookId;

  /// Starts loading as soon as the sheet asks for the picker. The marks
  /// follow the queue and the records while the sheet is open, so a volume
  /// that finishes turns from IN DOWNLOADS to SAVED.
  @override
  PickerState build() {
    ref.listen(downloadQueueProvider, (_, _) => _refreshMarks());
    ref.listen(downloadRecordsProvider, (_, _) => _refreshMarks());
    _load();
    return const PickerLoading();
  }

  /// Loads the contents again after a failure.
  void retry() {
    state = const PickerLoading();
    _load();
  }

  /// Ticks or unticks the volume at [number]. A volume in Downloads
  /// stays unticked.
  void toggle(int number) {
    final current = state;
    if (current is! PickerReady) return;
    if (current.inDownloads.contains(number)) return;
    final ticked = {...current.ticked};
    if (!ticked.remove(number)) ticked.add(number);
    state = current.withTicks(ticked);
  }

  /// Ticks every volume that can be ticked, or unticks all when they
  /// already are.
  void toggleAll() {
    final current = state;
    if (current is! PickerReady) return;
    state = current.withTicks(current.allTicked ? const {} : current.tickable);
  }

  /// Adds the ticked volumes to the Downloads tab in book order, and
  /// returns how many were added. With merge on in Settings, two or more
  /// ticked volumes go in as one row that makes a single EPUB.
  int download() {
    final current = state;
    if (current is! PickerReady) return 0;
    final queue = ref.read(downloadQueueProvider.notifier);
    final title = current.book.title;
    final volumes = [
      for (final volume in current.book.volumes)
        if (current.ticked.contains(volume.number)) volume,
    ];
    if (volumes.length > 1 && _mergeVolumes()) {
      return queue.addMerged(volumes, title) ? volumes.length : 0;
    }
    var added = 0;
    for (final volume in volumes) {
      if (queue.add(volume, title)) added++;
    }
    return added;
  }

  /// The merge choice from Settings; off until the settings are loaded.
  bool _mergeVolumes() {
    return ref.read(settingsProvider).value?.mergeVolumes ?? false;
  }

  /// Fetches the book. A book with one volume starts with it ticked,
  /// unless it was saved before.
  Future<void> _load() async {
    final result = await ref.read(novelRepositoryProvider).fetchBook(bookId);
    await ref.read(downloadRecordsProvider.future);
    if (!ref.mounted) return;
    switch (result) {
      case Err(:final message):
        state = PickerFailed(message);
      case Ok(data: final book):
        final isLoneNewVolume =
            book.volumes.length == 1 && !_savedVolumes().contains(1);
        final ticks = isLoneNewVolume ? const {1} : const <int>{};
        state = _marked(PickerReady(book, ticked: ticks));
    }
  }

  /// Marks the volumes again after the queue or the records changed.
  void _refreshMarks() {
    final current = state;
    if (current is PickerReady) state = _marked(current);
  }

  /// [ready] with its SAVED and IN DOWNLOADS marks as they are now. A
  /// ticked volume that went into Downloads is unticked.
  PickerReady _marked(PickerReady ready) {
    final inDownloads = {
      for (final task in ref.read(downloadQueueProvider))
        if (task.isActive)
          for (final volume in task.volumes)
            if (volume.bookId == bookId) volume.number,
    };
    return PickerReady(
      ready.book,
      ticked: ready.ticked.difference(inDownloads),
      saved: _savedVolumes(),
      inDownloads: inDownloads,
    );
  }

  /// Numbers of this book's volumes that have a download record.
  Set<int> _savedVolumes() {
    final records = ref.read(downloadRecordsProvider).value ?? const [];
    return {
      for (final record in records)
        if (record.bookId == bookId) record.volumeNumber,
    };
  }
}
