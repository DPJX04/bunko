import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/repositories/downloaded_volume_repository.dart';
import 'package:light_novel_downloader/repositories/settings_repository.dart';
import 'package:light_novel_downloader/state/download_records_state.dart';

import '../support/fakes.dart';

void main() {
  late MemoryStore store;

  ProviderContainer container([FakeStorage? storage]) {
    final container = ProviderContainer(
      overrides: [
        downloadedVolumeRepositoryProvider.overrideWithValue(
          DownloadedVolumeRepository(storage ?? FakeStorage(), store),
        ),
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(store)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => store = MemoryStore());

  test('records saved earlier are loaded at start', () async {
    await DownloadedVolumeRepository(FakeStorage(), store).addRecord(record(1));

    final records = await container().read(downloadRecordsProvider.future);

    expect(records.single.volumeTitle, '第1卷');
  });

  test('adding a record stores it and shows it at once', () async {
    final app = container();
    await app.read(downloadRecordsProvider.future);

    await app.read(downloadRecordsProvider.notifier).add(record(2));

    expect(app.read(downloadRecordsProvider).value!.single.volumeNumber, 2);
    final restarted = await container().read(downloadRecordsProvider.future);
    expect(restarted.single.volumeNumber, 2);
  });

  /// The volume numbers [app] lists now.
  List<int> listed(ProviderContainer app) {
    return [
      for (final r in app.read(downloadRecordsProvider).value!) r.volumeNumber,
    ];
  }

  /// Stores records for volumes 1 and 2, with their files at uri1 and uri2.
  Future<void> saveTwo(FakeStorage storage) async {
    final repository = DownloadedVolumeRepository(storage, store);
    await repository.addRecord(record(1, uri: 'uri1'));
    await repository.addRecord(record(2, uri: 'uri2'));
    storage
      ..place('uri1')
      ..place('uri2');
  }

  test('a volume whose file was deleted is dropped for good', () async {
    final storage = FakeStorage();
    await saveTwo(storage);
    storage.delete('uri2');
    final app = container(storage);
    await app.read(downloadRecordsProvider.future);

    await app.read(downloadRecordsProvider.notifier).sync();

    expect(listed(app), [1]);
    final restarted = container(storage);
    await restarted.read(downloadRecordsProvider.future);
    expect(listed(restarted), [1]);
  });

  test('an EPUB in the folder with no record is read back', () async {
    final storage = FakeStorage()
      ..place(
        'doc7',
        name: 'Book_07.epub',
        opf:
            '<dc:title>Book 7</dc:title>'
            '<dc:source>https://www.bilinovel.net/novel/5330.html</dc:source>'
            '<meta name="calibre:series" content="Book"/>',
      );
    final app = container(storage);
    await app.read(downloadRecordsProvider.future);

    await app.read(downloadRecordsProvider.notifier).sync();

    final added = app.read(downloadRecordsProvider).value!.single;
    expect((added.bookId, added.volumeNumber), ('5330', 7));
  });

  test('it lists the folder picked in Settings', () async {
    store.values['library_folder'] = 'content://tree/Novels';
    final storage = FakeStorage();
    final app = container(storage);
    await app.read(downloadRecordsProvider.future);

    await app.read(downloadRecordsProvider.notifier).sync();

    expect(storage.listed, ['content://tree/Novels']);
  });

  test('when the folder cannot be listed, every volume stays', () async {
    final storage = FakeStorage()..listFails = true;
    await saveTwo(storage);
    storage.delete('uri2');
    final app = container(storage);
    await app.read(downloadRecordsProvider.future);

    await app.read(downloadRecordsProvider.notifier).sync();

    expect(listed(app), [1, 2]);
  });

  test('a volume saved while the folder is listed is kept', () async {
    final storage = FakeStorage()..listGate = Completer<void>();
    await saveTwo(storage);
    storage.delete('uri2');
    final app = container(storage);
    await app.read(downloadRecordsProvider.future);
    final records = app.read(downloadRecordsProvider.notifier);

    final syncing = records.sync();
    // The download saves its file, which the listing may already see, and
    // then records it; the record replaces the one read back from the file.
    storage.place(
      'uri3',
      name: 'Book_03.epub',
      opf: '<dc:source>https://www.bilinovel.net/novel/5330.html</dc:source>',
    );
    final adding = records.add(record(3, uri: 'uri3'));
    storage.listGate!.complete();
    await syncing;
    await adding;

    expect(listed(app), [1, 3]);
    final restarted = container(storage);
    await restarted.read(downloadRecordsProvider.future);
    expect(listed(restarted), [1, 3]);
  });
}
