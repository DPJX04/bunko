import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/features/download/download_queue_controller.dart';
import 'package:light_novel_downloader/features/download/download_task.dart';
import 'package:light_novel_downloader/features/download/widgets/saved_snack_listener.dart';
import 'package:light_novel_downloader/models/result.dart';
import 'package:light_novel_downloader/models/volume.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';
import 'package:light_novel_downloader/widgets/app_theme.dart';

/// A queue the test moves by hand, which records the rows it opens.
class ScriptedQueue extends DownloadQueueController {
  ScriptedQueue(this.start);

  final List<DownloadTask> start;
  final opened = <int>[];
  Result<void> openResult = const Ok(null);

  @override
  List<DownloadTask> build() => start;

  /// Replaces every row, as the real queue does as it works.
  void show(List<DownloadTask> tasks) => state = tasks;

  @override
  Future<Result<void>> openSaved(int id) async {
    opened.add(id);
    return openResult;
  }
}

/// Volume [number] of book 5330 in [status].
DownloadTask task(int number, DownloadStatus status) {
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
    fileUri: status == DownloadStatus.done ? 'uri$number' : null,
  );
}

void main() {
  late ScriptedQueue queue;

  Future<void> show(WidgetTester tester, List<DownloadTask> start) async {
    queue = ScriptedQueue(start);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [downloadQueueProvider.overrideWith(() => queue)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const SavedSnackListener(child: Scaffold()),
        ),
      ),
    );
  }

  testWidgets('a volume that finishes is announced with OPEN', (tester) async {
    await show(tester, [task(1, DownloadStatus.downloading)]);

    queue.show([task(1, DownloadStatus.done)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Saved 第1卷'), findsOneWidget);
    await tester.tap(find.text('OPEN'));
    await tester.pump();
    expect(queue.opened, [1]);
  });

  testWidgets('only the latest save is announced, not a backlog', (
    tester,
  ) async {
    // Saves made while the app is in the background pile up unseen; on
    // coming back only the newest shows, not each in turn.
    await show(tester, [
      for (var n = 1; n <= 3; n++) task(n, DownloadStatus.downloading),
    ]);
    for (var saved = 1; saved <= 3; saved++) {
      queue.show([
        for (var n = 1; n <= 3; n++)
          task(
            n,
            n <= saved ? DownloadStatus.done : DownloadStatus.downloading,
          ),
      ]);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Saved 第3卷'), findsOneWidget);
    expect(find.text('Saved 第1卷'), findsNothing);
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved'), findsNothing);
  });

  testWidgets('rows saved before it started are not announced', (tester) async {
    await show(tester, [task(1, DownloadStatus.done)]);

    queue.show([task(1, DownloadStatus.done), task(2, DownloadStatus.waiting)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Saved'), findsNothing);
  });

  testWidgets('a file that cannot be opened says why', (tester) async {
    await show(tester, [task(1, DownloadStatus.downloading)]);
    queue.openResult = const Err(noReader);
    queue.show([task(1, DownloadStatus.done)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('OPEN'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(noReader), findsOneWidget);
  });
}
