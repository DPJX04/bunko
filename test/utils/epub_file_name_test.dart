import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/utils/epub_file_name.dart';

void main() {
  test('joins book, padded number and volume title', () {
    final name = epubFileName(
      bookTitle: 'SomeBook',
      volumeNumber: 2,
      volumeTitle: 'Volume2',
    );
    expect(name, 'SomeBook_02_Volume2.epub');
  });

  test('replaces characters Android rejects', () {
    final name = epubFileName(
      bookTitle: 'A/B:C?',
      volumeNumber: 1,
      volumeTitle: '第一卷　<上>',
    );
    expect(name, 'A B C_01_第一卷 上.epub');
  });

  test('drops leading and trailing dots', () {
    final name = epubFileName(
      bookTitle: '..Book.',
      volumeNumber: 3,
      volumeTitle: 'End...',
    );
    expect(name, 'Book_03_End.epub');
  });

  test('leaves out an empty volume title', () {
    final name = epubFileName(
      bookTitle: 'Book',
      volumeNumber: 1,
      volumeTitle: '  ',
    );
    expect(name, 'Book_01.epub');
  });

  test('drops a repeated book title and a bare volume number', () {
    final name = epubFileName(
      bookTitle: '酒醉就旅行的今里小姐',
      volumeNumber: 1,
      volumeTitle: '酒醉就旅行的今里小姐 1',
    );
    expect(name, '酒醉就旅行的今里小姐_01.epub');
  });

  test('keeps the rest of a volume title that repeats the book title', () {
    final name = epubFileName(
      bookTitle: 'Book',
      volumeNumber: 2,
      volumeTitle: 'Book 第二卷',
    );
    expect(name, 'Book_02_第二卷.epub');
  });

  test('stays under 255 bytes for long Chinese titles', () {
    final name = epubFileName(
      bookTitle: '长' * 200,
      volumeNumber: 12,
      volumeTitle: '卷' * 200,
    );
    expect(utf8.encode(name).length, lessThan(255));
  });

  test('a merged file names its first and last volume numbers', () {
    expect(
      mergedEpubFileName(
        bookTitle: 'Some: Book',
        firstNumber: 2,
        lastNumber: 4,
      ),
      'Some Book_02-04.epub',
    );
  });
}
