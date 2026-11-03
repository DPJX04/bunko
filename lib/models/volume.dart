/// One volume of a book, the unit the app downloads as one EPUB.
class Volume {
  const Volume({
    required this.bookId,
    required this.number,
    required this.title,
    required this.chapterCount,
  });

  /// The linovelib book id, such as '2356'.
  final String bookId;

  /// Position in the book's table of contents, starting at 1.
  final int number;

  /// Volume title as the site shows it, such as '第一卷'.
  final String title;

  /// How many chapters the volume has, for "12 of 30 chapters".
  final int chapterCount;

  /// True when both are the same volume of the same book.
  bool isSameVolume(Volume other) {
    return bookId == other.bookId && number == other.number;
  }
}
