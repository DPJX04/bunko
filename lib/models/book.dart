import 'volume.dart';

/// One book on linovelib with its volumes in table of contents order.
class Book {
  const Book({
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.volumes,
  });

  /// The linovelib book id, such as '2356'.
  final String bookId;

  final String title;
  final String author;

  /// Cover image URL, or null when the site shows none.
  final String? coverUrl;

  final List<Volume> volumes;
}
