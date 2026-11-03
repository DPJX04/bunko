import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Where bili_novel_packer writes the package file inside every EPUB.
const _opfPath = 'OEBPS/content.opf';

/// Adds the EPUB 2 cover tag, <meta name="cover" content="id"/>, to a packed
/// EPUB that marks its cover only the EPUB 3 way (properties="cover-image").
///
/// Many readers, eBoox among them, read only the EPUB 2 tag and otherwise
/// show a plain placeholder cover. The rebuilt zip stores every entry
/// uncompressed, which also puts `mimetype` first and uncompressed as the
/// EPUB spec requires. Returns [epub] unchanged when it has no cover or
/// already has the tag.
Uint8List withEpub2CoverMeta(Uint8List epub) {
  final archive = ZipDecoder().decodeBytes(epub);
  final opf = archive.findFile(_opfPath);
  if (opf == null) return epub;
  final patched = _addCoverMeta(utf8.decode(opf.content));
  if (patched == null) return epub;
  return _rebuild(archive, utf8.encode(patched));
}

/// Returns the OPF text with the cover tag added, or null if not needed.
String? _addCoverMeta(String opf) {
  if (opf.contains('name="cover"')) return null;
  final item = RegExp(
    r'<item\b[^>]*properties="cover-image"[^>]*>',
  ).firstMatch(opf);
  if (item == null || !opf.contains('</metadata>')) return null;
  final id = RegExp(r'\bid="([^"]+)"').firstMatch(item.group(0)!)?.group(1);
  if (id == null) return null;
  return opf.replaceFirst(
    '</metadata>',
    '  <meta name="cover" content="$id"/>\n  </metadata>',
  );
}

/// Zips every entry again in its original order, stored uncompressed, with
/// [opfBytes] in place of the old content.opf.
Uint8List _rebuild(Archive archive, List<int> opfBytes) {
  final rebuilt = Archive();
  for (final file in archive) {
    final data = file.name == _opfPath ? opfBytes : file.content;
    rebuilt.add(ArchiveFile.noCompress(file.name, data.length, data));
  }
  return ZipEncoder().encodeBytes(rebuilt);
}
