import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/features/library/library_screen.dart';
import 'package:light_novel_downloader/models/download_record.dart';
import 'package:light_novel_downloader/repositories/downloaded_volume_repository.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';
import 'package:light_novel_downloader/widgets/app_theme.dart';
import 'package:light_novel_downloader/widgets/emission_line.dart';
import 'package:light_novel_downloader/widgets/emission_tick_border.dart';
import 'package:light_novel_downloader/widgets/spectrum.dart';

import '../../support/fakes.dart';

/// Volume 6 of a second book, saved a day before [record]'s volumes.
DownloadRecord olderBookVolume() {
  return DownloadRecord(
    bookId: '114',
    volumeNumber: 6,
    bookTitle: '无赖勇者的鬼畜美学',
    volumeTitle: '第6卷',
    fileUri: 'uri114',
    downloadedAt: DateTime.utc(2026, 10, 31, 18),
  );
}

void main() {
  late FakeOpener opener;

  /// Opens the Library tab with [records] saved earlier.
  Future<void> show(WidgetTester tester, List<DownloadRecord> records) async {
    opener = FakeOpener();
    final store = MemoryStore();
    final repository = DownloadedVolumeRepository(FakeStorage(), store, opener);
    await tester.runAsync(() async {
      for (final r in records) {
        await repository.addRecord(r);
      }
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadedVolumeRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: LibraryScreen(onBrowse: () {}, onSettings: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with nothing saved, it shows the empty state', (tester) async {
    await show(tester, []);

    expect(find.text('No volumes yet'), findsOneWidget);
  });

  testWidgets('lists each book with its saved volumes', (tester) async {
    await show(tester, [record(1), record(2)]);

    expect(find.text('No volumes yet'), findsNothing);
    expect(find.text('酒醉就旅行的今里小姐'), findsOneWidget);
    expect(find.text('2 VOLUMES'), findsOneWidget);
    expect(find.text('第1卷'), findsOneWidget);
    expect(find.text('第2卷'), findsOneWidget);
  });

  testWidgets('the newest book starts open and older ones folded', (
    tester,
  ) async {
    await show(tester, [record(1), record(2), olderBookVolume()]);

    expect(find.text('无赖勇者的鬼畜美学'), findsOneWidget);
    expect(find.text('1 VOLUME'), findsOneWidget);
    expect(find.text('第1卷'), findsOneWidget);
    expect(find.text('第6卷'), findsNothing);
  });

  testWidgets('tapping a book folds or opens its volumes', (tester) async {
    await show(tester, [record(1), olderBookVolume()]);

    await tester.tap(find.text('酒醉就旅行的今里小姐'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('无赖勇者的鬼畜美学'));
    await tester.pumpAndSettle();

    expect(find.text('第1卷'), findsNothing);
    expect(find.text('第6卷'), findsOneWidget);
  });

  testWidgets('each book wears its own colour on its tick and lines', (
    tester,
  ) async {
    await show(tester, [record(1), olderBookVolume()]);
    await tester.tap(find.text('无赖勇者的鬼畜美学'));
    await tester.pumpAndSettle();

    final ticks = [
      for (final box in tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox),
      ))
        if (box.decoration case ShapeDecoration(
          shape: EmissionTickBorder(:final tickColor),
        ))
          tickColor,
    ];
    final lines = [
      for (final line in tester.widgetList<EmissionLine>(
        find.byType(EmissionLine),
      ))
        line.color,
    ];
    // Book 114 was saved first, so it takes the first book line.
    const spectrum = Spectrum.emission;
    expect(ticks, [spectrum.book(1), spectrum.book(0)]);
    expect(lines, [spectrum.book(1), spectrum.book(0)]);
  });

  testWidgets('tapping a volume opens it in a reader app', (tester) async {
    await show(tester, [record(1, uri: 'content://saved/1')]);

    await tester.tap(find.text('第1卷'));
    await tester.pump();

    expect(opener.opened, ['content://saved/1']);
  });

  testWidgets('a file that is gone says so', (tester) async {
    await show(tester, [record(1)]);
    opener.failure = fileMissing;

    await tester.tap(find.text('第1卷'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(fileMissing), findsOneWidget);
  });

  testWidgets('the settings button opens Settings', (tester) async {
    var opened = 0;
    final store = MemoryStore();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadedVolumeRepositoryProvider.overrideWithValue(
            DownloadedVolumeRepository(FakeStorage(), store, FakeOpener()),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: LibraryScreen(onBrowse: () {}, onSettings: () => opened++),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Settings'));

    expect(opened, 1);
  });
}
