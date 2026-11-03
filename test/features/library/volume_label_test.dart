import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/features/library/volume_label.dart';
import 'package:light_novel_downloader/l10n/l10n.dart';

void main() {
  final english = lookupAppLocalizations(const Locale('en'));
  final chinese = lookupAppLocalizations(const Locale('zh'));
  const book = '欢迎来到实力至上主义的教室 2年级篇';

  test('a volume named after its book shows only its number', () {
    expect(volumeLabel(english, book, '$book 1'), 'Volume 1');
    expect(volumeLabel(english, book, '$book 4.5'), 'Volume 4.5');
    expect(volumeLabel(chinese, book, '$book 4.5'), '第4.5卷');
  });

  test('a volume named after its book keeps the rest of its name', () {
    expect(volumeLabel(english, book, '$book 短篇集'), '短篇集');
  });

  test('a volume with its own name keeps it', () {
    expect(volumeLabel(english, '酒醉就旅行的今里小姐', '第2卷'), '第2卷');
  });

  test('a volume named exactly as its book keeps the name', () {
    expect(volumeLabel(english, book, book), book);
  });
}
