import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/download_record.dart';
import '../../models/result.dart';
import '../../repositories/downloaded_volume_repository.dart';
import '../../state/download_records_state.dart';

/// One book on the Library tab with its saved volumes, in book order.
class LibraryBook {
  const LibraryBook({
    required this.bookId,
    required this.title,
    required this.volumes,
    this.colorSlot = 0,
  });

  /// The linovelib book id, such as '5330'.
  final String bookId;

  final String title;
  final List<DownloadRecord> volumes;

  /// Which of the book colours marks this book: 0 for the book saved
  /// first, 1 for the next, and so on. A book keeps its slot as newer books
  /// are saved, so its colour stays the same.
  final int colorSlot;
}

/// The Library tab's books, the one saved most recently first. It follows
/// the download records, so a volume saved now shows up at once.
final libraryProvider = NotifierProvider<LibraryController, List<LibraryBook>>(
  LibraryController.new,
);

/// Lists saved volumes by book and opens them in a reader app.
class LibraryController extends Notifier<List<LibraryBook>> {
  @override
  List<LibraryBook> build() {
    final records = ref.watch(downloadRecordsProvider).value ?? const [];
    return _groupByBook(records);
  }

  /// Opens [volume]'s file in a reader app, or says why it cannot, such as
  /// when the file was deleted from Download/LightNovel.
  Future<Result<void>> open(DownloadRecord volume) {
    return ref.read(downloadedVolumeRepositoryProvider).open(volume.fileUri);
  }

  /// Groups [records] into books: volumes in book order, and the book with
  /// the newest save first.
  List<LibraryBook> _groupByBook(List<DownloadRecord> records) {
    final byBook = <String, List<DownloadRecord>>{};
    for (final record in records) {
      byBook.putIfAbsent(record.bookId, () => []).add(record);
    }
    final slots = _colorSlots(byBook);
    final books = <LibraryBook>[];
    for (final volumes in byBook.values) {
      volumes.sort((a, b) => a.volumeNumber.compareTo(b.volumeNumber));
      books.add(
        LibraryBook(
          bookId: volumes.first.bookId,
          title: _newestSave(volumes).bookTitle,
          volumes: volumes,
          colorSlot: slots[volumes.first.bookId]!,
        ),
      );
    }
    books.sort((a, b) {
      final aTime = _newestSave(a.volumes).downloadedAt;
      return _newestSave(b.volumes).downloadedAt.compareTo(aTime);
    });
    return books;
  }

  /// Numbers each book by when its first volume still saved was saved,
  /// oldest first, so a newly saved book takes the next slot.
  Map<String, int> _colorSlots(Map<String, List<DownloadRecord>> byBook) {
    DateTime firstSave(String bookId) {
      return byBook[bookId]!
          .map((volume) => volume.downloadedAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
    }

    final order = byBook.keys.toList()
      ..sort((a, b) {
        final byTime = firstSave(a).compareTo(firstSave(b));
        return byTime != 0 ? byTime : a.compareTo(b);
      });
    return {for (final (slot, bookId) in order.indexed) bookId: slot};
  }

  /// The volume of [volumes] that was saved last.
  DownloadRecord _newestSave(List<DownloadRecord> volumes) {
    var newest = volumes.first;
    for (final volume in volumes) {
      if (volume.downloadedAt.isAfter(newest.downloadedAt)) newest = volume;
    }
    return newest;
  }
}
