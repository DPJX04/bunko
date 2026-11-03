/// The saved note that one volume was downloaded: what it is and where the
/// EPUB went. The Library lists these, and the picker marks them.
class DownloadRecord {
  const DownloadRecord({
    required this.bookId,
    required this.volumeNumber,
    required this.bookTitle,
    required this.volumeTitle,
    required this.fileUri,
    required this.downloadedAt,
  });

  /// The linovelib book id, such as '5330'.
  final String bookId;

  /// Position in the book's table of contents, starting at 1. Upstream
  /// volumes have no id of their own, so this identifies the volume.
  final int volumeNumber;

  final String bookTitle;
  final String volumeTitle;

  /// Content URI of the EPUB in Download/LightNovel.
  final String fileUri;

  final DateTime downloadedAt;

  /// True when both records are about the same volume of the same book.
  bool isSameVolume(DownloadRecord other) {
    return bookId == other.bookId && volumeNumber == other.volumeNumber;
  }

  /// The record as JSON, for local storage.
  Map<String, Object?> toJson() {
    return {
      'bookId': bookId,
      'volumeNumber': volumeNumber,
      'bookTitle': bookTitle,
      'volumeTitle': volumeTitle,
      'fileUri': fileUri,
      'downloadedAt': downloadedAt.toUtc().toIso8601String(),
    };
  }

  /// Reads a record stored by [toJson]. Throws [FormatException] when a
  /// field is missing or has the wrong type.
  factory DownloadRecord.fromJson(Map<String, Object?> json) {
    final bookId = json['bookId'];
    final volumeNumber = json['volumeNumber'];
    final bookTitle = json['bookTitle'];
    final volumeTitle = json['volumeTitle'];
    final fileUri = json['fileUri'];
    final downloadedAt = json['downloadedAt'];
    if (bookId is! String ||
        volumeNumber is! int ||
        bookTitle is! String ||
        volumeTitle is! String ||
        fileUri is! String ||
        downloadedAt is! String) {
      throw const FormatException('Download record has a missing field');
    }
    return DownloadRecord(
      bookId: bookId,
      volumeNumber: volumeNumber,
      bookTitle: bookTitle,
      volumeTitle: volumeTitle,
      fileUri: fileUri,
      downloadedAt: DateTime.parse(downloadedAt),
    );
  }
}
