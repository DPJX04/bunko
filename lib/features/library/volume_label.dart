import '../../l10n/l10n.dart';

/// A volume's name under its book's header on Library, without the book
/// title it repeats: '欢迎来到…2年级篇 4.5' under that book reads
/// 'Volume 4.5', and '…2年级篇 短篇集' reads '短篇集'. A volume with a name
/// of its own, such as '第2卷', keeps it.
String volumeLabel(AppLocalizations l10n, String bookTitle, String volume) {
  if (!volume.startsWith(bookTitle)) return volume;
  final rest = volume.substring(bookTitle.length).trim();
  if (rest.isEmpty) return volume;
  return RegExp(r'^\d+(\.\d+)?$').hasMatch(rest)
      ? l10n.volumeNumber(rest)
      : rest;
}
