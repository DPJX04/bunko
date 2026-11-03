import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/l10n/l10n.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';

void main() {
  final english = lookupAppLocalizations(const Locale('en'));
  final chinese = lookupAppLocalizations(const Locale('zh'));

  test('a date reads as day and month in each language', () {
    expect(dayMonthOf(english, DateTime(2026, 11, 2)), '2 NOV');
    expect(dayMonthOf(english, DateTime(2026, 1, 31)), '31 JAN');
    expect(dayMonthOf(chinese, DateTime(2026, 11, 2)), '11月2日');
  });

  test('a date is shown in the phone own time zone', () {
    final utc = DateTime.utc(2026, 11, 2, 23, 30);
    final local = utc.toLocal();

    expect(dayMonthOf(chinese, utc), '${local.month}月${local.day}日');
  });

  test('error sentences turn into the picked language', () {
    expect(localizedError(english, noReader), noReader);
    expect(localizedError(chinese, noReader), chinese.errorNoReader);
    expect(localizedError(chinese, cancelled), '已取消。');
  });

  test('a sentence it does not know stays as it is', () {
    expect(localizedError(chinese, 'Disk full'), 'Disk full');
  });

  test('counts read naturally in both languages', () {
    expect(english.volumeCount(1), '1 VOLUME');
    expect(english.volumeCount(3), '3 VOLUMES');
    expect(chinese.volumeCount(3), '3 卷');
    expect(english.downloadVolumes(1), 'DOWNLOAD 1 VOLUME');
  });
}
