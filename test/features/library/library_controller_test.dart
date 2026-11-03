import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/features/library/library_controller.dart';
import 'package:light_novel_downloader/models/download_record.dart';
import 'package:light_novel_downloader/models/result.dart';
import 'package:light_novel_downloader/repositories/downloaded_volume_repository.dart';
import 'package:light_novel_downloader/state/download_records_state.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';

import '../../support/fakes.dart';

/// A record for volume [number] of book [bookId], saved at [minute].
DownloadRecord saved(String bookId, int number, {required int minute}) {
  return DownloadRecord(
    bookId: bookId,
    volumeNumber: number,
    bookTitle: 'Book $bookId',
    volumeTitle: 'Volume $number',
    fileUri: 'uri-$bookId-$number',
    downloadedAt: DateTime.utc(2026, 11, 2, 20, minute),
  );
}

void main() {
  late MemoryStore store;
  late FakeOpener opener;

  /// An app whose records are [records], loaded and ready.
  Future<ProviderContainer> start(List<DownloadRecord> records) async {
    store = MemoryStore();
    opener = FakeOpener();
    final repository = DownloadedVolumeRepository(FakeStorage(), store, opener);
    for (final record in records) {
      await repository.addRecord(record);
    }
    final container = ProviderContainer(
      overrides: [
        downloadedVolumeRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(downloadRecordsProvider.future);
    return container;
  }

  test('with no records there are no books', () async {
    final app = await start([]);

    expect(app.read(libraryProvider), isEmpty);
  });

  test('each book keeps a colour slot by when it was first saved', () async {
    final app = await start([
      saved('5330', 1, minute: 0),
      saved('114', 1, minute: 5),
      saved('114', 2, minute: 9),
      saved('777', 1, minute: 7),
    ]);

    final books = app.read(libraryProvider);

    expect(
      [for (final book in books) (book.bookId, book.colorSlot)],
      [('114', 1), ('777', 2), ('5330', 0)],
    );
  });

  test('volumes are grouped by book and listed in book order', () async {
    final app = await start([
      saved('114', 3, minute: 1),
      saved('114', 2, minute: 2),
      saved('5330', 1, minute: 0),
    ]);

    final books = app.read(libraryProvider);

    expect(books.map((book) => book.title), ['Book 114', 'Book 5330']);
    expect(books.first.volumes.map((v) => v.volumeNumber), [2, 3]);
  });

  test('the book downloaded most recently comes first', () async {
    final app = await start([
      saved('114', 1, minute: 1),
      saved('5330', 1, minute: 2),
    ]);

    final books = app.read(libraryProvider);

    expect(books.map((book) => book.bookId), ['5330', '114']);
  });

  test('a volume saved later shows up at once', () async {
    final app = await start([saved('114', 1, minute: 1)]);

    await app
        .read(downloadRecordsProvider.notifier)
        .add(saved('114', 4, minute: 5));

    expect(app.read(libraryProvider).single.volumes, hasLength(2));
  });

  test('opening a volume hands its file to a reader app', () async {
    final app = await start([saved('114', 2, minute: 1)]);
    final volume = app.read(libraryProvider).single.volumes.single;

    final opened = await app.read(libraryProvider.notifier).open(volume);

    expect(opened, isA<Ok<void>>());
    expect(opener.opened, ['uri-114-2']);
  });

  test('a file that is gone says so', () async {
    final app = await start([saved('114', 2, minute: 1)]);
    opener.failure = fileMissing;
    final volume = app.read(libraryProvider).single.volumes.single;

    final opened = await app.read(libraryProvider.notifier).open(volume);

    expect((opened as Err<void>).message, fileMissing);
  });
}
