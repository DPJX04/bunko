import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/models/download_record.dart';
import 'package:light_novel_downloader/models/result.dart';
import 'package:light_novel_downloader/repositories/downloaded_volume_repository.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';

import '../support/fakes.dart';

void main() {
  late MemoryStore store;

  DownloadedVolumeRepository repository() {
    return DownloadedVolumeRepository(FakeStorage(), store);
  }

  setUp(() => store = MemoryStore());

  test('a record is still there after the app starts again', () async {
    await repository().addRecord(record(1, minute: 6));

    final loaded = await repository().loadRecords();

    final records = (loaded as Ok<List<DownloadRecord>>).data;
    expect(records, hasLength(1));
    expect(records.single.bookId, '5330');
    expect(records.single.volumeNumber, 1);
    expect(records.single.volumeTitle, '第1卷');
    expect(records.single.fileUri, 'uri');
    expect(records.single.downloadedAt, DateTime.utc(2026, 11, 1, 18, 6));
  });

  test('downloading a volume again replaces its old record', () async {
    await repository().addRecord(record(1, uri: 'old'));
    await repository().addRecord(record(2));
    await repository().addRecord(record(1, uri: 'new'));

    final loaded = await repository().loadRecords();

    final records = (loaded as Ok<List<DownloadRecord>>).data;
    expect(records.map((r) => r.fileUri), ['uri', 'new']);
  });

  test('a stored entry with a missing field is skipped', () async {
    await repository().addRecord(record(1));
    final key = store.values.keys.single;
    store.values[key] = store.values[key]!.replaceFirst(
      '[',
      '[{"bookId":"5330"},',
    );

    final loaded = await repository().loadRecords();

    expect((loaded as Ok<List<DownloadRecord>>).data, hasLength(1));
  });

  test('nothing stored yet loads as no records', () async {
    final loaded = await repository().loadRecords();

    expect((loaded as Ok<List<DownloadRecord>>).data, isEmpty);
  });

  group('saving a volume', () {
    late FakeStorage storage;
    late File epub;

    setUp(() {
      storage = FakeStorage();
      final folder = Directory.systemTemp.createTempSync('save_test');
      addTearDown(() => folder.deleteSync(recursive: true));
      epub = File('${folder.path}/book_01.epub')..writeAsBytesSync([1, 2, 3]);
    });

    test('a volume saved before is written over its recorded copy', () async {
      final repository = DownloadedVolumeRepository(storage, store);
      await repository.addRecord(record(1, uri: 'content://downloads/7'));

      final saved = await repository.save(
        epub,
        bookId: '5330',
        volumeNumber: 1,
      );

      expect(storage.replaced, ['content://downloads/7']);
      expect((saved as Ok<String>).data, 'content://downloads/7');
    });

    test('a volume never saved before gets a new file', () async {
      final repository = DownloadedVolumeRepository(storage, store);
      await repository.addRecord(record(1, uri: 'content://downloads/7'));

      await repository.save(epub, bookId: '5330', volumeNumber: 2);

      expect(storage.replaced, [null]);
    });

    test('the cache copy is deleted once saved', () async {
      final repository = DownloadedVolumeRepository(storage, store);

      await repository.save(epub, bookId: '5330', volumeNumber: 1);

      expect(epub.existsSync(), isFalse);
    });
  });

  test('open hands the saved file to a reader app', () async {
    final opener = FakeOpener();
    final repository = DownloadedVolumeRepository(FakeStorage(), store, opener);

    final opened = await repository.open('content://media/downloads/7');

    expect(opened, isA<Ok<void>>());
    expect(opener.opened, ['content://media/downloads/7']);
  });

  test('open says why a file could not be opened', () async {
    final opener = FakeOpener()..failure = fileMissing;
    final repository = DownloadedVolumeRepository(FakeStorage(), store, opener);

    final opened = await repository.open('content://media/downloads/7');

    expect((opened as Err<void>).message, fileMissing);
  });

  test('a volume saved in a merge is not written over by itself', () async {
    final storage = FakeStorage();
    final repository = DownloadedVolumeRepository(storage, store);
    await repository.addRecord(record(2, uri: 'merged'));
    await repository.addRecord(record(3, uri: 'merged'));
    final epub = File('${Directory.systemTemp.createTempSync().path}/v3.epub')
      ..writeAsStringSync('epub');

    await repository.save(epub, bookId: '5330', volumeNumber: 3);

    expect(storage.replaced.single, isNull);
  });
}
