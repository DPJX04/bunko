/// What the download notification shows while the queue runs: a [title]
/// such as 'Downloading 第2卷', a [text] such as '42% · 2 more waiting', the
/// [book] title, and the [percent] its progress bar fills, from 0 to 100.
///
/// A record, so two notices with the same fields are equal.
typedef DownloadNotice = ({
  String title,
  String text,
  String book,
  int percent,
});
