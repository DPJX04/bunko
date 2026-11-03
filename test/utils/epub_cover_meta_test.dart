import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/utils/epub_cover_meta.dart';

/// The content.opf shape bili_novel_packer writes, with or without a cover.
String opf({required bool withCover}) {
  final coverItem = withCover
      ? '<item id="images_000019_jpg" href="images/000019.jpg" '
            'media-type="image/jpeg" properties="cover-image"/>'
      : '';
  return '<package><metadata><dc:title>Book</dc:title></metadata>'
      '<manifest>$coverItem</manifest></package>';
}

/// Builds a small EPUB the way upstream does: mimetype first, deflated.
Uint8List epubWith(String opfText) {
  final archive = Archive()
    ..add(ArchiveFile.string('mimetype', 'application/epub+zip'))
    ..add(ArchiveFile.string('OEBPS/content.opf', opfText))
    ..add(ArchiveFile.string('OEBPS/chapter000001.xhtml', '<p>text</p>'));
  return ZipEncoder().encodeBytes(archive);
}

/// Reads one entry of an EPUB as text.
String entry(Uint8List epub, String name) {
  final archive = ZipDecoder().decodeBytes(epub);
  return utf8.decode(archive.findFile(name)!.content);
}

void main() {
  test('adds the EPUB 2 cover tag inside metadata', () {
    final fixed = withEpub2CoverMeta(epubWith(opf(withCover: true)));

    final text = entry(fixed, 'OEBPS/content.opf');
    expect(text, contains('<meta name="cover" content="images_000019_jpg"/>'));
    expect(text.indexOf('name="cover"'), lessThan(text.indexOf('</metadata>')));
  });

  test('keeps every entry, with mimetype first and stored uncompressed', () {
    final fixed = withEpub2CoverMeta(epubWith(opf(withCover: true)));

    final archive = ZipDecoder().decodeBytes(fixed);
    expect(archive.map((file) => file.name), [
      'mimetype',
      'OEBPS/content.opf',
      'OEBPS/chapter000001.xhtml',
    ]);
    expect(archive.first.compression, CompressionType.none);
    expect(entry(fixed, 'mimetype'), 'application/epub+zip');
    expect(entry(fixed, 'OEBPS/chapter000001.xhtml'), '<p>text</p>');
  });

  test('leaves an EPUB with no cover unchanged', () {
    final epub = epubWith(opf(withCover: false));
    expect(withEpub2CoverMeta(epub), same(epub));
  });

  test('does not add the tag twice', () {
    final once = withEpub2CoverMeta(epubWith(opf(withCover: true)));
    expect(withEpub2CoverMeta(once), same(once));
  });
}
