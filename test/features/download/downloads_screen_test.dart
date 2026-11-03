import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/features/download/download_queue_controller.dart';
import 'package:light_novel_downloader/features/download/download_task.dart';
import 'package:light_novel_downloader/features/download/downloads_screen.dart';
import 'package:light_novel_downloader/models/result.dart';
import 'package:light_novel_downloader/models/volume.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';
import 'package:light_novel_downloader/widgets/app_theme.dart';

import '../../support/fonts.dart';

/// A queue frozen at the given rows, which records Retry, Cancel and
/// Clear taps.
class ShownQueue extends DownloadQueueController {
  ShownQueue(this.tasks);

  final List<DownloadTask> tasks;
  final retried = <int>[];
  final cancelled = <int>[];
  final opened = <int>[];
  Result<void> openResult = const Ok(null);
  var clears = 0;

  @override
  List<DownloadTask> build() => tasks;

  @override
  void retry(int id) => retried.add(id);

  @override
  void cancel(int id) => cancelled.add(id);

  @override
  void clearSaved() => clears++;

  @override
  Future<Result<void>> openSaved(int id) async {
    opened.add(id);
    return openResult;
  }
}

/// A row for volume [number] of book 5330.
DownloadTask task(
  int number,
  DownloadStatus status, {
  int done = 0,
  String? error,
}) {
  return DownloadTask(
    id: number,
    volumes: [
      Volume(
        bookId: '5330',
        number: number,
        title: '第$number卷',
        chapterCount: 8,
      ),
    ],
    bookTitle: '酒醉就旅行的今里小姐',
    status: status,
    chaptersDone: done,
    chaptersTotal: 8,
    errorMessage: error,
  );
}

void main() {
  late ShownQueue queue;

  Future<void> show(WidgetTester tester, List<DownloadTask> tasks) async {
    queue = ShownQueue(tasks);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [downloadQueueProvider.overrideWith(() => queue)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: DownloadsScreen(onBrowse: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with nothing added, it shows the empty state', (tester) async {
    await show(tester, []);

    expect(find.text('No downloads running'), findsOneWidget);
  });

  testWidgets('each row names its volume, book and percentage', (tester) async {
    await show(tester, [task(1, DownloadStatus.downloading, done: 3)]);

    expect(find.text('No downloads running'), findsNothing);
    expect(find.text('第1卷'), findsOneWidget);
    expect(find.text('酒醉就旅行的今里小姐'), findsOneWidget);
    expect(find.text('37%'), findsOneWidget);
  });

  testWidgets('waiting and saved rows say so in place of a percentage', (
    tester,
  ) async {
    await show(tester, [
      task(1, DownloadStatus.done, done: 8),
      task(2, DownloadStatus.waiting),
    ]);

    expect(find.text('SAVED'), findsOneWidget);
    expect(find.text('Saved to Download/LightNovel'), findsOneWidget);
    expect(find.text('WAITING'), findsOneWidget);
  });

  testWidgets('a failed row gives the reason, and RETRY retries it', (
    tester,
  ) async {
    await show(tester, [task(4, DownloadStatus.failed, error: noInternet)]);

    expect(find.text('FAILED'), findsOneWidget);
    expect(find.text(noInternet), findsOneWidget);

    await tester.tap(find.text('RETRY'));

    expect(queue.retried, [4]);
  });

  testWidgets('waiting and downloading rows can be cancelled; others not', (
    tester,
  ) async {
    await show(tester, [
      task(1, DownloadStatus.done, done: 8),
      task(2, DownloadStatus.downloading, done: 3),
      task(3, DownloadStatus.waiting),
      task(4, DownloadStatus.failed, error: noInternet),
    ]);

    expect(find.byTooltip('Cancel download'), findsNWidgets(2));
  });

  testWidgets('cancel asks first, and KEEP leaves the row', (tester) async {
    await show(tester, [task(2, DownloadStatus.downloading, done: 3)]);

    await tester.tap(find.byTooltip('Cancel download'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel 第2卷?'), findsOneWidget);
    await tester.tap(find.text('KEEP'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel 第2卷?'), findsNothing);
    expect(queue.cancelled, isEmpty);
  });

  testWidgets('CANCEL DOWNLOAD in the dialog cancels the row', (tester) async {
    await show(tester, [task(3, DownloadStatus.waiting)]);

    await tester.tap(find.byTooltip('Cancel download'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CANCEL DOWNLOAD'));
    await tester.pumpAndSettle();

    expect(queue.cancelled, [3]);
  });

  for (final fontScale in [1.0, 1.3]) {
    testWidgets(
      'at font scale $fontScale the dialog stacks its buttons full width',
      (tester) async {
        await tester.runAsync(loadArchivo);
        // The Honor test phone: 1280 px at density 560, so 366 dp wide.
        tester.view.physicalSize = const Size(1280, 2800);
        tester.view.devicePixelRatio = 3.5;
        tester.platformDispatcher.textScaleFactorTestValue = fontScale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await show(tester, [task(3, DownloadStatus.waiting)]);

        await tester.tap(find.byTooltip('Cancel download'));
        await tester.pumpAndSettle();

        final keep = tester.getRect(find.widgetWithText(TextButton, 'KEEP'));
        final cancel = tester.getRect(
          find.widgetWithText(TextButton, 'CANCEL DOWNLOAD'),
        );
        final sentence = tester.getRect(
          find.text('It leaves the queue before it starts.'),
        );
        expect(cancel.bottom, lessThan(keep.top));
        expect(keep.left, cancel.left);
        expect(keep.right, cancel.right);
        expect(keep.left, sentence.left);
      },
    );
  }

  testWidgets('without saved rows there is no CLEAR', (tester) async {
    await show(tester, [task(2, DownloadStatus.waiting)]);

    expect(find.text('CLEAR'), findsNothing);
  });

  testWidgets('CLEAR clears the saved rows', (tester) async {
    await show(tester, [
      task(1, DownloadStatus.done, done: 8),
      task(2, DownloadStatus.waiting),
    ]);

    await tester.tap(find.text('CLEAR'));

    expect(queue.clears, 1);
  });

  testWidgets('a saved row has OPEN, which opens its file', (tester) async {
    await show(tester, [task(1, DownloadStatus.done, done: 8)]);

    await tester.tap(find.text('OPEN'));
    await tester.pump();

    expect(queue.opened, [1]);
  });

  testWidgets('a file that cannot be opened says why', (tester) async {
    await show(tester, [task(1, DownloadStatus.done, done: 8)]);
    queue.openResult = const Err(fileMissing);

    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(fileMissing), findsOneWidget);
  });
}
