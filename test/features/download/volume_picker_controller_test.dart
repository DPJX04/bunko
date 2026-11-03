import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/features/download/download_queue_controller.dart';
import 'package:light_novel_downloader/features/download/download_task.dart';
import 'package:light_novel_downloader/features/download/volume_picker_controller.dart';
import 'package:light_novel_downloader/models/book.dart';
import 'package:light_novel_downloader/models/result.dart';
import 'package:light_novel_downloader/repositories/downloaded_volume_repository.dart';
import 'package:light_novel_downloader/repositories/novel_repository.dart';
import 'package:light_novel_downloader/state/settings_state.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';

import '../../support/fakes.dart';

void main() {
  late FakeWorld world;
  late ProviderContainer container;

  final picker = volumePickerProvider('5330');

  /// Keeps the picker alive and waits until it stops loading.
  Future<PickerState> settled() {
    final done = Completer<PickerState>();
    container.listen<PickerState>(picker, (_, next) {
      if (next is! PickerLoading && !done.isCompleted) done.complete(next);
    }, fireImmediately: true);
    return done.future;
  }

  PickerReady ready() => container.read(picker) as PickerReady;

  VolumePickerController controller() => container.read(picker.notifier);

  /// Opens a fresh app on a fake book with [volumeCount] volumes, with
  /// [savedVolumes] already downloaded on an earlier run.
  Future<void> start({
    int volumeCount = 1,
    List<int> savedVolumes = const [],
  }) async {
    world = FakeWorld(volumeCount: volumeCount);
    final repository = DownloadedVolumeRepository(world.storage, world.store);
    for (final number in savedVolumes) {
      await repository.addRecord(record(number));
    }
    container = ProviderContainer(
      overrides: [
        ...world.overrides,
        downloadQueueProvider.overrideWith(
          () => DownloadQueueController(gapBetweenVolumes: Duration.zero),
        ),
      ],
    );
  }

  /// Puts volume [number] in the queue, held mid-download until released.
  Future<void> queueHeld(int number) async {
    world.source.hold = Completer<void>();
    final fetched = await container
        .read(novelRepositoryProvider)
        .fetchBook('5330');
    final book = (fetched as Ok<Book>).data;
    container
        .read(downloadQueueProvider.notifier)
        .add(book.volumes[number - 1], book.title);
  }

  tearDown(() {
    final hold = world.source.hold;
    if (hold != null && !hold.isCompleted) hold.complete();
    container.dispose();
    world.dispose();
  });

  test('shows the book and its volumes once the contents arrive', () async {
    await start(volumeCount: 2);

    final state = await settled() as PickerReady;

    expect(state.book.title, '酒醉就旅行的今里小姐');
    expect(state.book.author, '结城弘');
    expect(state.book.volumes.map((v) => v.title), ['第1卷', '第2卷']);
    expect(state.book.volumes.first.chapterCount, 2);
  });

  test('a book with one volume starts with it ticked', () async {
    await start();

    final state = await settled() as PickerReady;

    expect(state.ticked, {1});
  });

  test('a one-volume book already saved starts unticked', () async {
    await start(savedVolumes: [1]);

    final state = await settled() as PickerReady;

    expect(state.ticked, isEmpty);
    expect(state.saved, {1});
  });

  test('a book with several volumes starts with none ticked', () async {
    await start(volumeCount: 3);

    final state = await settled() as PickerReady;

    expect(state.ticked, isEmpty);
  });

  test('ticking a volume again unticks it', () async {
    await start(volumeCount: 3);
    await settled();

    controller().toggle(2);
    expect(ready().ticked, {2});

    controller().toggle(2);
    expect(ready().ticked, isEmpty);
  });

  test('saved volumes are marked, start unticked and can be ticked', () async {
    await start(volumeCount: 3, savedVolumes: [2]);
    await settled();

    expect(ready().saved, {2});
    expect(ready().ticked, isEmpty);

    controller().toggle(2);
    expect(ready().ticked, {2});
  });

  test('a volume in Downloads is marked and cannot be ticked', () async {
    await start(volumeCount: 3);
    await queueHeld(2);
    await settled();

    expect(ready().inDownloads, {2});

    controller().toggle(2);
    expect(ready().ticked, isEmpty);
  });

  test(
    'Select all ticks every volume it can, and again unticks them',
    () async {
      await start(volumeCount: 3, savedVolumes: [1]);
      await queueHeld(3);
      await settled();

      controller().toggleAll();
      expect(ready().ticked, {1, 2});
      expect(ready().allTicked, isTrue);

      controller().toggleAll();
      expect(ready().ticked, isEmpty);
    },
  );

  test('Select all with some ticked ticks the rest', () async {
    await start(volumeCount: 3);
    await settled();
    controller().toggle(2);

    controller().toggleAll();

    expect(ready().ticked, {1, 2, 3});
  });

  test('Download adds only the ticked volumes, in book order', () async {
    await start(volumeCount: 3);
    await settled();
    controller().toggle(3);
    controller().toggle(2);

    final added = controller().download();

    expect(added, 2);
    final tasks = container.read(downloadQueueProvider);
    expect(tasks.map((task) => task.volume.number), [2, 3]);
    expect(tasks.first.bookTitle, '酒醉就旅行的今里小姐');
  });

  test('Download with nothing ticked adds nothing', () async {
    await start(volumeCount: 3);
    await settled();

    expect(controller().download(), 0);
    expect(container.read(downloadQueueProvider), isEmpty);
  });

  test(
    'a volume that finishes while the picker is open becomes saved',
    () async {
      await start(volumeCount: 2);
      await queueHeld(1);
      await settled();
      expect(ready().inDownloads, {1});

      world.source.hold!.complete();
      final done = Completer<void>();
      container.listen<List<DownloadTask>>(downloadQueueProvider, (_, next) {
        if (next.single.status == DownloadStatus.done) done.complete();
      });
      await done.future;
      await pumpEventQueue();

      expect(ready().inDownloads, isEmpty);
      expect(ready().saved, {1});
    },
  );

  test('offline shows a plain sentence, and Retry loads again', () async {
    await start();
    world.source.offline = true;

    final failed = await settled() as PickerFailed;
    expect(failed.message, noInternet);

    world.source.offline = false;
    controller().retry();
    expect(container.read(picker), isA<PickerLoading>());
    await pumpEventQueue();
    expect(container.read(picker), isA<PickerReady>());
  });

  test('with merge on, the ticked volumes go in as one row', () async {
    await start(volumeCount: 3);
    await container.read(settingsProvider.notifier).setMergeVolumes(true);
    await settled();
    controller().toggle(3);
    controller().toggle(2);

    final added = controller().download();

    expect(added, 2);
    final row = container.read(downloadQueueProvider).single;
    expect(row.volumes.map((v) => v.number), [2, 3]);
  });

  test('with merge on, one ticked volume still goes in on its own', () async {
    await start(volumeCount: 3);
    await container.read(settingsProvider.notifier).setMergeVolumes(true);
    await settled();
    controller().toggle(2);

    controller().download();

    expect(container.read(downloadQueueProvider).single.volumes, hasLength(1));
  });
}
