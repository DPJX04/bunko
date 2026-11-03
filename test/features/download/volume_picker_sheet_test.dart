import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:async';

import 'package:light_novel_downloader/features/download/download_queue_controller.dart';
import 'package:light_novel_downloader/features/download/volume_picker_sheet.dart';
import 'package:light_novel_downloader/models/book.dart';
import 'package:light_novel_downloader/models/result.dart';
import 'package:light_novel_downloader/repositories/downloaded_volume_repository.dart';
import 'package:light_novel_downloader/repositories/novel_repository.dart';
import 'package:light_novel_downloader/state/settings_state.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';
import 'package:light_novel_downloader/widgets/app_theme.dart';

import '../../support/fakes.dart';

void main() {
  late FakeWorld world;
  late ProviderContainer container;
  late int viewTaps;

  /// Opens the app on a button that shows the picker for book 5330, with
  /// [savedVolumes] downloaded before and [queuedVolume] mid-download.
  Future<void> openPicker(
    WidgetTester tester, {
    int volumeCount = 1,
    bool offline = false,
    List<int> savedVolumes = const [],
    int? queuedVolume,
  }) async {
    world = FakeWorld(volumeCount: volumeCount);
    world.source.offline = offline;
    addTearDown(world.dispose);
    await tester.runAsync(() async {
      final repository = DownloadedVolumeRepository(world.storage, world.store);
      for (final number in savedVolumes) {
        await repository.addRecord(record(number));
      }
    });
    viewTaps = 0;
    container = ProviderContainer(
      overrides: [
        ...world.overrides,
        downloadQueueProvider.overrideWith(
          () => DownloadQueueController(gapBetweenVolumes: Duration.zero),
        ),
      ],
    );
    addTearDown(container.dispose);
    if (queuedVolume != null) {
      world.source.hold = Completer<void>();
      addTearDown(world.source.hold!.complete);
      await tester.runAsync(() async {
        final fetched = await container
            .read(novelRepositoryProvider)
            .fetchBook('5330');
        final book = (fetched as Ok<Book>).data;
        container
            .read(downloadQueueProvider.notifier)
            .add(book.volumes[queuedVolume - 1], book.title);
      });
    }
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => VolumePickerSheet(
                    bookId: '5330',
                    bookTitle: '酒醉就旅行的今里小姐',
                    onViewDownloads: () => viewTaps++,
                  ),
                ),
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pumpAndSettle();
  }

  /// The picker's one filled button, whatever it says.
  FilledButton downloadButton(WidgetTester tester) {
    return tester.widget<FilledButton>(find.byType(FilledButton));
  }

  /// The label on the picker's filled button.
  String downloadLabel(WidgetTester tester) {
    final label = find.descendant(
      of: find.byType(FilledButton),
      matching: find.byType(Text),
    );
    return tester.widget<Text>(label).data!;
  }

  testWidgets('starts with nothing ticked and a plain, disabled DOWNLOAD', (
    tester,
  ) async {
    await openPicker(tester, volumeCount: 2);

    expect(find.text('第1卷'), findsOneWidget);
    expect(find.text('第2卷'), findsOneWidget);
    expect(find.text('2 CHAPTERS'), findsNWidgets(2));
    expect(find.text('结城弘 · LINOVELIB #5330'), findsOneWidget);
    expect(find.text('SELECT ALL'), findsOneWidget);
    expect(downloadLabel(tester), 'DOWNLOAD');
    expect(downloadButton(tester).onPressed, isNull);
  });

  testWidgets('the button counts the ticked volumes', (tester) async {
    await openPicker(tester, volumeCount: 3);

    await tester.tap(find.text('第2卷'));
    await tester.pump();
    expect(downloadLabel(tester), 'DOWNLOAD 1 VOLUME');
    expect(downloadButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('SELECT ALL'));
    await tester.pump();
    expect(downloadLabel(tester), 'DOWNLOAD 3 VOLUMES');
  });

  testWidgets('a book with one volume has no SELECT ALL row', (tester) async {
    await openPicker(tester);

    expect(find.text('SELECT ALL'), findsNothing);
    expect(downloadLabel(tester), 'DOWNLOAD 1 VOLUME');
  });

  testWidgets('a saved volume is marked SAVED and starts unticked', (
    tester,
  ) async {
    await openPicker(tester, volumeCount: 2, savedVolumes: [1]);

    expect(find.text('2 CHAPTERS · SAVED'), findsOneWidget);
    expect(downloadLabel(tester), 'DOWNLOAD');
  });

  testWidgets('a volume in Downloads is marked and cannot be ticked', (
    tester,
  ) async {
    await openPicker(tester, volumeCount: 2, queuedVolume: 2);

    expect(find.text('2 CHAPTERS · IN DOWNLOADS'), findsOneWidget);
    final tile = tester.widget<CheckboxListTile>(
      find.widgetWithText(CheckboxListTile, '第2卷'),
    );
    expect(tile.onChanged, isNull);
  });

  testWidgets('a volume in Downloads has its title dimmed', (tester) async {
    await openPicker(tester, volumeCount: 2, queuedVolume: 2);

    final queued = tester.widget<Text>(find.text('第2卷')).style!.color!;
    final free = tester.widget<Text>(find.text('第1卷')).style!.color!;
    expect(queued.a, closeTo(0.38, 0.01));
    expect(free.a, 1);
  });

  testWidgets('offline shows the reason and a RETRY button', (tester) async {
    await openPicker(tester, offline: true);

    expect(find.text(noInternet), findsOneWidget);
    expect(find.text('RETRY'), findsOneWidget);
    expect(find.textContaining('DOWNLOAD'), findsNothing);
  });

  testWidgets('the error fits its content instead of filling the sheet', (
    tester,
  ) async {
    await openPicker(tester, offline: true);

    // The test screen is 600 tall, so a sheet stretched to its 85% cap
    // would be 510.
    final sheet = tester.getSize(find.byType(VolumePickerSheet));
    expect(sheet.height, lessThan(400));
  });

  testWidgets('Download closes the sheet and offers a way to Downloads', (
    tester,
  ) async {
    await openPicker(tester);

    await tester.tap(find.text('DOWNLOAD 1 VOLUME'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(VolumePickerSheet), findsNothing);
    expect(container.read(downloadQueueProvider).single.volume.number, 1);
    expect(find.text('1 volume added'), findsOneWidget);

    await tester.tap(find.text('VIEW'));
    await tester.pump();
    expect(viewTaps, 1);
  });

  testWidgets('the snackbar counts every volume added', (tester) async {
    await openPicker(tester, volumeCount: 3);

    await tester.tap(find.text('SELECT ALL'));
    await tester.pump();
    await tester.tap(find.text('DOWNLOAD 3 VOLUMES'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(container.read(downloadQueueProvider), hasLength(3));
    expect(find.text('3 volumes added'), findsOneWidget);
  });

  testWidgets('with merge on, the button and snackbar say one EPUB', (
    tester,
  ) async {
    await openPicker(tester, volumeCount: 3);
    await tester.runAsync(
      () => container.read(settingsProvider.notifier).setMergeVolumes(true),
    );
    await tester.pump();

    await tester.tap(find.text('SELECT ALL'));
    await tester.pump();
    expect(downloadLabel(tester), 'DOWNLOAD 3 AS ONE EPUB');

    await tester.tap(find.text('DOWNLOAD 3 AS ONE EPUB'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('3 volumes added as one EPUB'), findsOneWidget);
  });
}
