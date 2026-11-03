import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/features/download/download_notice.dart';
import 'package:light_novel_downloader/features/download/download_task.dart';
import 'package:light_novel_downloader/l10n/l10n.dart';
import 'package:light_novel_downloader/models/volume.dart';

/// A row for volume [number] of book 5330, [done] of 8 chapters in.
DownloadTask task(int number, DownloadStatus status, {int done = 0}) {
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
  );
}

/// The notice's words in English.
final english = lookupAppLocalizations(const Locale('en'));

void main() {
  test('there is no notice while nothing waits or downloads', () {
    expect(noticeFor(english, []), isNull);
    expect(
      noticeFor(english, [
        task(1, DownloadStatus.done, done: 8),
        task(2, DownloadStatus.failed),
      ]),
      isNull,
    );
  });

  test('names the volume downloading now and its percentage', () {
    final notice = noticeFor(english, [
      task(1, DownloadStatus.done, done: 8),
      task(2, DownloadStatus.downloading, done: 3),
    ])!;

    expect(notice.title, 'Downloading 第2卷');
    expect(notice.text, '37%');
    expect(notice.book, '酒醉就旅行的今里小姐');
    expect(notice.percent, 37);
  });

  test('counts the volumes still waiting', () {
    final two = noticeFor(english, [
      task(1, DownloadStatus.downloading, done: 3),
      task(2, DownloadStatus.waiting),
      task(3, DownloadStatus.waiting),
    ])!;
    final one = noticeFor(english, [
      task(1, DownloadStatus.downloading, done: 3),
      task(2, DownloadStatus.waiting),
    ])!;

    expect(two.text, '37% · 2 more waiting');
    expect(one.text, '37% · 1 more waiting');
  });

  test('between volumes it names the next one', () {
    final notice = noticeFor(english, [
      task(1, DownloadStatus.done, done: 8),
      task(2, DownloadStatus.waiting),
      task(3, DownloadStatus.waiting),
    ])!;

    expect(notice.title, 'Downloading 第2卷');
    expect(notice.text, '0% · 1 more waiting');
  });

  test('a merged row is named from its first to its last volume', () {
    final merged = DownloadTask(
      id: 9,
      volumes: [
        for (final n in [2, 3, 4])
          Volume(bookId: '5330', number: n, title: '第$n卷', chapterCount: 8),
      ],
      bookTitle: '酒醉就旅行的今里小姐',
      status: DownloadStatus.downloading,
    );

    expect(noticeFor(english, [merged])!.title, 'Downloading 第2卷 – 第4卷');
  });
}
