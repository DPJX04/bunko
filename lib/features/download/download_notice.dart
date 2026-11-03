import '../../l10n/l10n.dart';
import '../../models/download_notice.dart';
import 'download_task.dart';

/// The notification for the queue as it stands, in [l10n]'s language, or
/// null when nothing is waiting or downloading: 'Downloading 第2卷' and
/// '42% · 2 more waiting'.
///
/// Between two volumes nothing is downloading, so it names the next one.
DownloadNotice? noticeFor(AppLocalizations l10n, List<DownloadTask> tasks) {
  final active = [
    for (final task in tasks)
      if (task.isActive) task,
  ];
  if (active.isEmpty) return null;
  final current = active.firstWhere(
    (task) => task.status == DownloadStatus.downloading,
    orElse: () => active.first,
  );
  final waiting = active.length - 1;
  return (
    title: l10n.noticeDownloading(current.title),
    text: waiting == 0
        ? '${current.percent}%'
        : l10n.noticeMoreWaiting(current.percent, waiting),
    book: current.bookTitle,
    percent: current.percent,
  );
}
