import '../../models/volume.dart';

/// Where one volume stands on the Downloads tab. A cancelled volume leaves
/// the list, so it needs no status of its own.
enum DownloadStatus { waiting, downloading, done, failed }

/// One row on the Downloads tab: the volume it downloads, or the volumes
/// it merges into one EPUB, and how far it has got.
class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.volumes,
    required this.bookTitle,
    this.status = DownloadStatus.waiting,
    this.chaptersDone = 0,
    this.chaptersTotal = 0,
    this.errorMessage,
    this.fileUri,
  });

  /// Unique within one app run, so Retry finds the right row.
  final int id;

  /// The volumes this row makes one EPUB of, in book order: one, or
  /// several when the owner merges volumes.
  final List<Volume> volumes;

  final String bookTitle;
  final DownloadStatus status;
  final int chaptersDone;
  final int chaptersTotal;

  /// One readable sentence when [status] is failed, otherwise null.
  final String? errorMessage;

  /// Content URI of the saved EPUB once [status] is done, otherwise null.
  final String? fileUri;

  /// The first volume, which also names the book.
  Volume get volume => volumes.first;

  /// True when the row merges several volumes into one EPUB.
  bool get isMerged => volumes.length > 1;

  /// What the row is called: its volume's title, or the first and last
  /// titles of a merge, such as '第2卷 – 第4卷'.
  String get title {
    if (!isMerged) return volume.title;
    return '${volumes.first.title} – ${volumes.last.title}';
  }

  /// True when this row downloads [other], alone or merged.
  bool includes(Volume other) {
    return volumes.any((volume) => volume.isSameVolume(other));
  }

  /// True while the volume is waiting or downloading, the rows that can be
  /// cancelled and that the Downloads tab badge counts.
  bool get isActive {
    return status == DownloadStatus.waiting ||
        status == DownloadStatus.downloading;
  }

  /// Progress from 0 to 100, by chapters. It stays at 99 at most until the
  /// file is saved, because the cover and the save come after the last
  /// chapter.
  int get percent {
    if (status == DownloadStatus.done) return 100;
    if (chaptersTotal == 0) return 0;
    final share = chaptersDone * 100 ~/ chaptersTotal;
    return share > 99 ? 99 : share;
  }

  /// Returns a copy with a new [status] and progress. [errorMessage] is
  /// always replaced, because null clears it.
  DownloadTask copyWith({
    required DownloadStatus status,
    int? chaptersDone,
    int? chaptersTotal,
    String? errorMessage,
    String? fileUri,
  }) {
    return DownloadTask(
      id: id,
      volumes: volumes,
      bookTitle: bookTitle,
      status: status,
      chaptersDone: chaptersDone ?? this.chaptersDone,
      chaptersTotal: chaptersTotal ?? this.chaptersTotal,
      errorMessage: errorMessage,
      fileUri: fileUri ?? this.fileUri,
    );
  }
}
