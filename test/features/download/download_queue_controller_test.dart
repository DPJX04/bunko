import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/features/download/download_queue_controller.dart';
import 'package:light_novel_downloader/features/download/download_task.dart';
import 'package:light_novel_downloader/models/book.dart';
import 'package:light_novel_downloader/models/result.dart';
import 'package:light_novel_downloader/repositories/novel_repository.dart';
import 'package:light_novel_downloader/state/download_records_state.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';

import '../../support/fakes.dart';

void main() {
  late FakeWorld world;
  late ProviderContainer container;
  late Book book;

  DownloadQueueController queue() {
    return container.read(downloadQueueProvider.notifier);
  }

  List<DownloadTask> tasks() => container.read(downloadQueueProvider);

  /// Waits until the queue's tasks pass [check].
  Future<void> until(bool Function(List<DownloadTask> tasks) check) {
    final done = Completer<void>();
    container.listen<List<DownloadTask>>(downloadQueueProvider, (_, next) {
      if (check(next) && !done.isCompleted) done.complete();
    }, fireImmediately: true);
    return done.future.timeout(const Duration(seconds: 10));
  }

  bool allSettled(List<DownloadTask> tasks) {
    return tasks.every((task) {
      return task.status == DownloadStatus.done ||
          task.status == DownloadStatus.failed;
    });
  }

  /// Opens a fresh app on a fake book with [volumeCount] volumes, as the
  /// picker leaves it: the table of contents already fetched.
  Future<void> start({int volumeCount = 1}) async {
    world = FakeWorld(volumeCount: volumeCount);
    container = ProviderContainer(
      overrides: [
        ...world.overrides,
        downloadQueueProvider.overrideWith(
          () => DownloadQueueController(gapBetweenVolumes: Duration.zero),
        ),
      ],
    );
    final fetched = await container
        .read(novelRepositoryProvider)
        .fetchBook('5330');
    book = (fetched as Ok<Book>).data;
  }

  tearDown(() {
    container.dispose();
    world.dispose();
  });

  test('an added volume is packed, saved to Download and recorded', () async {
    await start();

    queue().add(book.volumes.single, book.title);
    await until(allSettled);

    expect(tasks().single.status, DownloadStatus.done);
    expect(world.storage.saved, ['酒醉就旅行的今里小姐_01_第1卷.epub']);
    final records = await container.read(downloadRecordsProvider.future);
    expect(records.single.volumeTitle, '第1卷');
    expect(records.single.bookTitle, '酒醉就旅行的今里小姐');
    expect(
      records.single.fileUri,
      'content://media/external_primary/downloads/1',
    );
  });

  test(
    'the percentage follows chapters and stays under 100 until saved',
    () async {
      await start();
      final percents = <int>[];
      container.listen<List<DownloadTask>>(downloadQueueProvider, (_, next) {
        final percent = next.single.percent;
        if (percents.isEmpty || percents.last != percent) percents.add(percent);
      });

      queue().add(book.volumes.single, book.title);
      await until(allSettled);

      expect(percents, [0, 50, 99, 100]);
    },
  );

  test('a second volume waits until the first is saved', () async {
    await start(volumeCount: 2);

    queue().add(book.volumes[0], book.title);
    queue().add(book.volumes[1], book.title);

    expect(tasks().map((task) => task.status), [
      DownloadStatus.downloading,
      DownloadStatus.waiting,
    ]);
    await until(allSettled);
    expect(world.storage.saved, [
      '酒醉就旅行的今里小姐_01_第1卷.epub',
      '酒醉就旅行的今里小姐_02_第2卷.epub',
    ]);
  });

  test(
    'offline fails the row with a plain sentence, and Retry works',
    () async {
      await start();
      world.source.offline = true;

      queue().add(book.volumes.single, book.title);
      await until(allSettled);

      expect(tasks().single.status, DownloadStatus.failed);
      expect(tasks().single.errorMessage, noInternet);
      expect(world.storage.saved, isEmpty);

      world.source.offline = false;
      queue().retry(tasks().single.id);
      expect(tasks().single.status, DownloadStatus.downloading);
      expect(tasks().single.errorMessage, isNull);
      await until(allSettled);
      expect(tasks().single.status, DownloadStatus.done);
    },
  );

  test('a failed volume does not stop the ones after it', () async {
    await start(volumeCount: 3);
    world.source.failingVolumes.add(2);

    for (final volume in book.volumes) {
      queue().add(volume, book.title);
    }
    await until(allSettled);

    expect(tasks().map((task) => task.status), [
      DownloadStatus.done,
      DownloadStatus.failed,
      DownloadStatus.done,
    ]);
    expect(world.storage.saved, [
      '酒醉就旅行的今里小姐_01_第1卷.epub',
      '酒醉就旅行的今里小姐_03_第3卷.epub',
    ]);

    world.source.failingVolumes.clear();
    queue().retry(tasks()[1].id);
    await until(allSettled);
    expect(tasks()[1].status, DownloadStatus.done);
  });

  test('a volume already waiting or downloading is refused', () async {
    await start(volumeCount: 2);
    world.source.hold = Completer<void>();

    expect(queue().add(book.volumes[0], book.title), isTrue);
    expect(queue().add(book.volumes[1], book.title), isTrue);
    expect(queue().add(book.volumes[0], book.title), isFalse);
    expect(queue().add(book.volumes[1], book.title), isFalse);

    expect(tasks(), hasLength(2));
    world.source.hold!.complete();
    await until(allSettled);
  });

  test('adding a finished volume again replaces its row', () async {
    await start();
    queue().add(book.volumes.single, book.title);
    await until(allSettled);

    expect(queue().add(book.volumes.single, book.title), isTrue);

    expect(tasks().single.status, DownloadStatus.downloading);
    await until(allSettled);
    expect(tasks().single.status, DownloadStatus.done);
  });

  test('cancelling a waiting volume removes it before it starts', () async {
    await start(volumeCount: 2);
    world.source.hold = Completer<void>();
    queue().add(book.volumes[0], book.title);
    queue().add(book.volumes[1], book.title);

    queue().cancel(tasks()[1].id);

    expect(tasks().single.volume.number, 1);
    world.source.hold!.complete();
    await until(allSettled);
    expect(world.storage.saved, ['酒醉就旅行的今里小姐_01_第1卷.epub']);
  });

  test(
    'cancelling the running volume stops it, and the next one starts',
    () async {
      await start(volumeCount: 2);
      world.source.hold = Completer<void>();
      queue().add(book.volumes[0], book.title);
      queue().add(book.volumes[1], book.title);

      queue().cancel(tasks()[0].id);
      world.source.hold!.complete();
      await until(allSettled);

      expect(tasks().single.volume.number, 2);
      expect(tasks().single.status, DownloadStatus.done);
      expect(world.storage.saved, ['酒醉就旅行的今里小姐_02_第2卷.epub']);
      final records = await container.read(downloadRecordsProvider.future);
      expect(records.map((r) => r.volumeNumber), [2]);
    },
  );

  test(
    'a volume cancelled during the pause between volumes never starts',
    () async {
      world = FakeWorld(volumeCount: 2);
      container = ProviderContainer(
        overrides: [
          ...world.overrides,
          downloadQueueProvider.overrideWith(
            () => DownloadQueueController(
              gapBetweenVolumes: const Duration(milliseconds: 200),
            ),
          ),
        ],
      );
      final fetched = await container
          .read(novelRepositoryProvider)
          .fetchBook('5330');
      book = (fetched as Ok<Book>).data;
      queue().add(book.volumes[0], book.title);
      queue().add(book.volumes[1], book.title);
      await until((tasks) => tasks.first.status == DownloadStatus.done);

      queue().cancel(tasks()[1].id);
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(world.storage.saved, ['酒醉就旅行的今里小姐_01_第1卷.epub']);
    },
  );

  test('cancel leaves a row that finished in the meantime', () async {
    await start();
    queue().add(book.volumes.single, book.title);
    await until(allSettled);

    queue().cancel(tasks().single.id);

    expect(tasks().single.status, DownloadStatus.done);
  });

  test('the background notice runs while the queue does', () async {
    await start(volumeCount: 2);

    queue().add(book.volumes[0], book.title);
    queue().add(book.volumes[1], book.title);
    await until(allSettled);
    await pumpEventQueue();

    final calls = world.background.calls;
    expect(calls.take(2), ['permission', 'start 0%']);
    expect(calls, contains('update 50%'));
    expect(calls.where((call) => call == 'stop'), hasLength(1));
    expect(calls.last, 'stop');
  });

  test('cancelling the only volume ends the notice', () async {
    await start();
    world.source.hold = Completer<void>();
    queue().add(book.volumes.single, book.title);

    queue().cancel(tasks().single.id);
    await pumpEventQueue();

    expect(world.background.calls.last, 'stop');
    world.source.hold!.complete();
  });

  test('Clear removes saved rows and keeps the records', () async {
    await start(volumeCount: 2);
    world.source.failingVolumes.add(2);
    queue().add(book.volumes[0], book.title);
    queue().add(book.volumes[1], book.title);
    await until(allSettled);

    queue().clearSaved();

    expect(tasks().single.status, DownloadStatus.failed);
    final records = await container.read(downloadRecordsProvider.future);
    expect(records.map((r) => r.volumeNumber), [1]);
  });

  test('the active count follows waiting and downloading rows', () async {
    await start(volumeCount: 3);
    world.source.hold = Completer<void>();
    expect(container.read(activeDownloadCountProvider), 0);

    for (final volume in book.volumes) {
      queue().add(volume, book.title);
    }
    expect(container.read(activeDownloadCountProvider), 3);

    queue().cancel(tasks()[2].id);
    expect(container.read(activeDownloadCountProvider), 2);

    world.source.hold!.complete();
    await until(allSettled);
    expect(container.read(activeDownloadCountProvider), 0);
  });

  test('a saved row opens its file in a reader app', () async {
    await start();
    queue().add(book.volumes.single, book.title);
    await until(allSettled);

    final opened = await queue().openSaved(tasks().single.id);

    expect(opened, isA<Ok<void>>());
    expect(world.opener.opened, [
      'content://media/external_primary/downloads/1',
    ]);
  });

  test('a file that cannot be opened gives the sentence back', () async {
    await start();
    queue().add(book.volumes.single, book.title);
    await until(allSettled);
    world.opener.failure = noReader;

    final opened = await queue().openSaved(tasks().single.id);

    expect((opened as Err<void>).message, noReader);
  });

  test('merged volumes become one EPUB with a record per volume', () async {
    await start(volumeCount: 3);

    queue().addMerged([book.volumes[1], book.volumes[2]], book.title);
    await until(allSettled);

    expect(tasks().single.title, '第2卷 – 第3卷');
    expect(tasks().single.status, DownloadStatus.done);
    expect(world.storage.saved, ['酒醉就旅行的今里小姐_02-03.epub']);
    final records = await container.read(downloadRecordsProvider.future);
    expect(records.map((r) => r.volumeNumber), [2, 3]);
    expect(records.map((r) => r.fileUri).toSet(), hasLength(1));
  });

  test('a merge is refused when one of its volumes is in the queue', () async {
    await start(volumeCount: 3);
    world.source.hold = Completer<void>();
    queue().add(book.volumes[1], book.title);

    final added = queue().addMerged([
      book.volumes[0],
      book.volumes[1],
    ], book.title);

    expect(added, isFalse);
    expect(tasks(), hasLength(1));
    world.source.hold!.complete();
    await until(allSettled);
  });
}
