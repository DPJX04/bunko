import '../models/download_record.dart';
import '../models/library_file.dart';

/// What an EPUB's package file says about it. Bunko writes the book's
/// page as dc:source, the book title as calibre:series and the volume
/// title as dc:title; an EPUB from elsewhere may have only some of these.
typedef EpubDetails = ({
  String? bookId,
  String? bookTitle,
  String? volumeTitle,
});

/// Reads [opf], the text of an EPUB's content.opf.
EpubDetails epubDetails(String opf) {
  final source = _element(opf, 'dc:source');
  final bookId = source == null
      ? null
      : RegExp(r'/novel/(\d+)\.html').firstMatch(source)?.group(1);
  return (
    bookId: bookId,
    bookTitle: _meta(opf, 'calibre:series'),
    volumeTitle: _element(opf, 'dc:title'),
  );
}

/// The download records for the EPUBs in the library folder: the record
/// of each file Bunko already knows, every volume of a merged file
/// included, and a record read back from each file it does not, such as
/// after a reinstall or in a newly chosen folder. Records whose files are
/// gone are left out.
List<DownloadRecord> recordsForFiles(
  List<DownloadRecord> records,
  List<LibraryFile> files,
) {
  final byUri = <String, List<DownloadRecord>>{};
  for (final record in records) {
    byUri.putIfAbsent(record.fileUri, () => []).add(record);
  }
  return [
    for (final file in files) ...(byUri[file.uri] ?? [_readBack(file)]),
  ];
}

/// A record for a file no record describes, from its details and name.
/// A book with no id from its page is keyed by its title instead.
DownloadRecord _readBack(LibraryFile file) {
  final details = file.opf == null ? null : epubDetails(file.opf!);
  final name = _nameParts(file.name);
  final bookTitle = details?.bookTitle ?? name.book;
  return DownloadRecord(
    bookId: details?.bookId ?? 'file:$bookTitle',
    volumeNumber: name.number ?? 0,
    bookTitle: bookTitle,
    volumeTitle: details?.volumeTitle ?? name.book,
    fileUri: file.uri,
    downloadedAt: file.modified,
  );
}

/// Splits a Bunko file name, 'Book_05_4.5.epub' or 'Book_02-04.epub', into
/// the book part and the first volume number. Any other name is all book.
({String book, int? number}) _nameParts(String fileName) {
  final stem = fileName.replaceFirst(
    RegExp(r'\.epub$', caseSensitive: false),
    '',
  );
  final match = RegExp(r'^(.+)_(\d{2,})(?:-\d{2,})?(?:_.*)?$').firstMatch(stem);
  if (match == null) return (book: stem, number: null);
  return (book: match.group(1)!, number: int.parse(match.group(2)!));
}

/// The text of the first <[tag]> element in [xml], or null.
String? _element(String xml, String tag) {
  final match = RegExp('<$tag\\b[^>]*>([^<]*)</$tag>').firstMatch(xml);
  return _text(match?.group(1));
}

/// The content of the <meta name="[name]"> element in [xml], or null.
String? _meta(String xml, String name) {
  for (final meta in RegExp(r'<meta\b[^>]*>').allMatches(xml)) {
    final tag = meta.group(0)!;
    if (!tag.contains('name="$name"')) continue;
    return _text(RegExp(r'content="([^"]*)"').firstMatch(tag)?.group(1));
  }
  return null;
}

/// Unescapes XML text and trims it; empty text counts as none.
String? _text(String? raw) {
  if (raw == null) return null;
  final text = raw
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&amp;', '&')
      .trim();
  return text.isEmpty ? null : text;
}
