/// Builds the EPUB file name, such as 'SomeBook_02_Volume2.epub'.
///
/// Characters Android or reader apps reject are replaced with a space, and
/// each title is cut to [maxTitleLength] characters so the name stays under
/// the 255 byte limit even when every character is Chinese (3 bytes each).
String epubFileName({
  required String bookTitle,
  required int volumeNumber,
  required String volumeTitle,
}) {
  final book = _cleanTitle(bookTitle);
  final volume = _volumePart(bookTitle, volumeTitle, volumeNumber);
  final number = volumeNumber.toString().padLeft(2, '0');
  if (volume.isEmpty) return '${book}_$number.epub';
  return '${book}_${number}_$volume.epub';
}

/// Builds the name of an EPUB that merges several volumes, such as
/// 'SomeBook_02-04.epub' for volumes 2 to 4.
String mergedEpubFileName({
  required String bookTitle,
  required int firstNumber,
  required int lastNumber,
}) {
  final first = firstNumber.toString().padLeft(2, '0');
  final last = lastNumber.toString().padLeft(2, '0');
  return '${_cleanTitle(bookTitle)}_$first-$last.epub';
}

/// Returns the cleaned volume title without a repeated book title, as
/// upstream does: 'Book 2' in book 'Book' becomes '2', and a bare number
/// equal to [volumeNumber] is dropped, since the name already has it.
String _volumePart(String bookTitle, String volumeTitle, int volumeNumber) {
  final book = bookTitle.trim();
  var title = volumeTitle.trim();
  if (book.isNotEmpty && title.startsWith(book)) {
    title = title.substring(book.length);
  }
  final clean = _cleanTitle(title);
  return clean == '$volumeNumber' ? '' : clean;
}

/// Longest title part kept in a file name, in characters.
const maxTitleLength = 36;

/// Characters not allowed in file names, plus the full width space.
final _unsafeCharacters = RegExp(r'[:*?"\\/<>|\x00-\x1F　]');

/// Makes one title safe for a file name. Rules follow bili_novel_packer's
/// own file name cleaning in lib/novel_packer.dart.
String _cleanTitle(String title) {
  var clean = title.replaceAll(_unsafeCharacters, ' ');
  clean = clean.replaceAll(RegExp(r'\s+'), ' ').trim();
  clean = clean.replaceAll(RegExp(r'^\.+|\.+$'), '').trim();
  final characters = clean.runes.toList();
  if (characters.length <= maxTitleLength) return clean;
  return String.fromCharCodes(characters.take(maxTitleLength)).trim();
}
