/// Every fixed value the app uses: site addresses, folder names and timing.
///
/// No other file writes a URL, folder name or delay by hand. There are no
/// secret keys in this app, and none belong here.
abstract final class AppConfig {
  /// Home page the Browse tab opens. www.linovelib.com redirects here, and
  /// it is the same host bili_novel_packer downloads from.
  static const siteHomeUrl = 'https://www.bilinovel.net/';

  /// Book page address for a book id. bili_novel_packer reads the id from it.
  static String bookUrl(String bookId) {
    return 'https://www.bilinovel.net/novel/$bookId.html';
  }

  /// Folder inside the phone's Download folder where EPUBs are saved.
  static const downloadFolder = 'LightNovel';

  /// Folder inside the app cache where an EPUB is built before saving.
  static const workFolder = 'epub_work';

  /// Pause between two volumes in the queue, on top of upstream's own
  /// rate limit of 15 page and 10 image requests per minute.
  static const delayBetweenVolumes = Duration(seconds: 5);

  /// How many chapters past the one being packed may load their text while
  /// its images download. Text and images have separate upstream limits,
  /// so loading ahead sends no request sooner than its limit allows; it
  /// only stops the text waiting for the images.
  static const chaptersFetchedAhead = 4;

  /// Puts the chapter title above each chapter's text, as upstream offers.
  static const addChapterTitle = true;

  /// Forces the 'light' or 'dark' plate for screenshot builds, passed with
  /// `--dart-define=FORCE_THEME=light`. Empty, the default, follows the
  /// phone's dark mode.
  static const forcedTheme = String.fromEnvironment('FORCE_THEME');
}
