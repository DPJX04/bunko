import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/models/download_record.dart';
import 'package:light_novel_downloader/models/library_file.dart';
import 'package:light_novel_downloader/utils/library_files.dart';

/// The package file Bunko writes, trimmed to the parts Library reads.
String opf({
  String title = '欢迎来到实力至上主义的教室 2年级篇 4.5',
  String series = '欢迎来到实力至上主义的教室 2年级篇',
  String source = 'https://www.bilinovel.net/novel/5369.html',
}) {
  return '<package><metadata>'
      '<dc:title>$title</dc:title>'
      '<dc:creator>衣笠彰梧</dc:creator>'
      '<dc:source>$source</dc:source>'
      '<meta name="calibre:series" content="$series"/>'
      '<meta name="calibre:series_index" content="4.5"/>'
      '</metadata></package>';
}

final saved = DateTime.utc(2026, 11, 3, 10);

LibraryFile file(String uri, String name, {String? opf}) {
  return LibraryFile(uri: uri, name: name, modified: saved, opf: opf);
}

DownloadRecord record(String uri, int number) {
  return DownloadRecord(
    bookId: '5369',
    volumeNumber: number,
    bookTitle: 'Book',
    volumeTitle: 'Volume $number',
    fileUri: uri,
    downloadedAt: DateTime.utc(2026, 11, 1),
  );
}

void main() {
  group('epubDetails', () {
    test('reads the book, its id and the volume title', () {
      final details = epubDetails(opf());

      expect(details.bookId, '5369');
      expect(details.bookTitle, '欢迎来到实力至上主义的教室 2年级篇');
      expect(details.volumeTitle, '欢迎来到实力至上主义的教室 2年级篇 4.5');
    });

    test('an EPUB from elsewhere gives what it has', () {
      final details = epubDetails(
        '<package><metadata><dc:title>Some Novel</dc:title>'
        '</metadata></package>',
      );

      expect(details.bookId, isNull);
      expect(details.bookTitle, isNull);
      expect(details.volumeTitle, 'Some Novel');
    });

    test('escaped characters read back as text', () {
      final details = epubDetails(opf(series: 'A &amp; B'));

      expect(details.bookTitle, 'A & B');
    });
  });

  group('recordsForFiles', () {
    test('a file Bunko recorded keeps its record', () {
      final kept = record('uri1', 1);

      final records = recordsForFiles([kept], [file('uri1', 'Book_01.epub')]);

      expect(records, [kept]);
    });

    test('a record whose file is gone is dropped', () {
      final records = recordsForFiles(
        [record('uri1', 1), record('uri2', 2)],
        [file('uri1', 'Book_01.epub')],
      );

      expect(records.map((r) => r.fileUri), ['uri1']);
    });

    test('every volume of a merged file stays with it', () {
      final records = recordsForFiles(
        [record('merged', 2), record('merged', 3)],
        [file('merged', 'Book_02-03.epub')],
      );

      expect(records.map((r) => r.volumeNumber), [2, 3]);
    });

    test('an unrecorded Bunko file is read back from its details', () {
      final records = recordsForFiles(const [], [
        file('doc5', '欢迎来到实力至上主义的教室 2年级篇_05_4.5.epub', opf: opf()),
      ]);

      final added = records.single;
      expect(added.bookId, '5369');
      expect(added.bookTitle, '欢迎来到实力至上主义的教室 2年级篇');
      expect(added.volumeNumber, 5);
      expect(added.volumeTitle, '欢迎来到实力至上主义的教室 2年级篇 4.5');
      expect(added.fileUri, 'doc5');
      expect(added.downloadedAt, saved);
    });

    test('an EPUB from elsewhere is listed under its file name', () {
      final records = recordsForFiles(const [], [
        file('doc9', 'Some Novel.epub'),
      ]);

      final added = records.single;
      expect(added.bookTitle, 'Some Novel');
      expect(added.volumeTitle, 'Some Novel');
      expect(added.bookId, 'file:Some Novel');
      expect(added.volumeNumber, 0);
    });

    test('a merged file read back is listed by its first volume', () {
      final records = recordsForFiles(const [], [
        file('doc2', 'Book_02-04.epub', opf: opf(title: 'Book 2-4')),
      ]);

      expect(records.single.volumeNumber, 2);
    });
  });
}
