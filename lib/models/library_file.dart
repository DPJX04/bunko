/// One EPUB found in the library folder.
class LibraryFile {
  const LibraryFile({
    required this.uri,
    required this.name,
    required this.modified,
    this.opf,
  });

  /// The file's content URI, which opens it.
  final String uri;

  /// The file name, such as 'SomeBook_02_Volume2.epub'.
  final String name;

  /// When the file was last written.
  final DateTime modified;

  /// The text of the EPUB's package file (content.opf), read only for files
  /// no download record describes yet; null otherwise, or when unreadable.
  final String? opf;
}
