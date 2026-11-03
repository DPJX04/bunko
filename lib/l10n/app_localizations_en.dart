// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabBrowse => 'BROWSE';

  @override
  String get tabDownloads => 'DOWNLOADS';

  @override
  String get tabLibrary => 'LIBRARY';

  @override
  String queueCount(int count) {
    return '$count in the queue';
  }

  @override
  String get browseHome => 'Site home';

  @override
  String get browseBack => 'Back';

  @override
  String get downloadVolumesTooltip => 'Download volumes';

  @override
  String get download => 'DOWNLOAD';

  @override
  String get retry => 'RETRY';

  @override
  String get open => 'OPEN';

  @override
  String get view => 'VIEW';

  @override
  String get browseBooks => 'BROWSE BOOKS';

  @override
  String get errorPageDidNotLoad => 'The page did not load. Tap Retry.';

  @override
  String get errorNoInternet =>
      'No internet connection. Check Wi‑Fi and tap Retry.';

  @override
  String get errorTooSlow => 'The site took too long to answer. Tap Retry.';

  @override
  String get errorBlocked =>
      'The site blocked the request. Open the book page in Browse once, then tap Retry.';

  @override
  String get errorTooManyRequests =>
      'Too many requests. Wait a minute, then tap Retry.';

  @override
  String get errorNotFound => 'This page was not found on the site.';

  @override
  String get errorPageChanged =>
      'The site page looked different than expected. The app may need an update.';

  @override
  String get errorCouldNotSave =>
      'Could not save the file. Check free space on the phone.';

  @override
  String get errorFileMissing =>
      'This file is no longer in Download/LightNovel. Download the volume again.';

  @override
  String get errorNoReader =>
      'No app on this phone opens EPUB files. Install a reader such as eBoox.';

  @override
  String get errorCancelled => 'Cancelled.';

  @override
  String get errorSomethingWentWrong => 'Something went wrong. Tap Retry.';

  @override
  String get clear => 'CLEAR';

  @override
  String get clearTooltip => 'Remove saved rows. The files stay.';

  @override
  String get downloadsEmptyTitle => 'No downloads running';

  @override
  String get downloadsEmptyMessage =>
      'Open a book in Browse and tap Download. Volumes wait here in order and download one at a time.';

  @override
  String downloadVolumes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'DOWNLOAD $count VOLUMES',
      one: 'DOWNLOAD 1 VOLUME',
    );
    return '$_temp0';
  }

  @override
  String downloadMerged(int count) {
    return 'DOWNLOAD $count AS ONE EPUB';
  }

  @override
  String get thisBook => 'This book';

  @override
  String siteId(String bookId) {
    return 'LINOVELIB #$bookId';
  }

  @override
  String authorAndSiteId(String author, String bookId) {
    return '$author · LINOVELIB #$bookId';
  }

  @override
  String get readingContents => 'Reading the table of contents.';

  @override
  String get selectAll => 'SELECT ALL';

  @override
  String chapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count CHAPTERS',
      one: '1 CHAPTER',
    );
    return '$_temp0';
  }

  @override
  String get markInDownloads => ' · IN DOWNLOADS';

  @override
  String get markSaved => ' · SAVED';

  @override
  String cancelTitle(String title) {
    return 'Cancel $title?';
  }

  @override
  String get cancelRunning =>
      'It stops before its next chapter, and nothing is saved.';

  @override
  String get cancelWaiting => 'It leaves the queue before it starts.';

  @override
  String get cancelDownload => 'CANCEL DOWNLOAD';

  @override
  String get keep => 'KEEP';

  @override
  String get cancelDownloadTooltip => 'Cancel download';

  @override
  String get statusWaiting => 'WAITING';

  @override
  String get statusSaved => 'SAVED';

  @override
  String get statusFailed => 'FAILED';

  @override
  String get savedToFolder => 'Saved to Download/LightNovel';

  @override
  String volumesAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volumes added',
      one: '1 volume added',
    );
    return '$_temp0';
  }

  @override
  String volumesAddedMerged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count volumes added as one EPUB',
      one: '1 volume added as one EPUB',
    );
    return '$_temp0';
  }

  @override
  String savedVolume(String title) {
    return 'Saved $title';
  }

  @override
  String get settings => 'Settings';

  @override
  String get libraryEmptyTitle => 'No volumes yet';

  @override
  String get libraryEmptyMessage =>
      'Every volume you download is saved to Download/LightNovel and listed here by book, ready to open in your reader. After a reinstall, pick that folder in Settings → Library folder to bring them back.';

  @override
  String volumeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count VOLUMES',
      one: '1 VOLUME',
    );
    return '$_temp0';
  }

  @override
  String get opensInReader => 'Opens in your reader';

  @override
  String get showVolumes => 'Shows its volumes';

  @override
  String get hideVolumes => 'Hides its volumes';

  @override
  String savedOn(String date) {
    return 'SAVED $date';
  }

  @override
  String dayMonth(String day, String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'JAN',
      '2': 'FEB',
      '3': 'MAR',
      '4': 'APR',
      '5': 'MAY',
      '6': 'JUN',
      '7': 'JUL',
      '8': 'AUG',
      '9': 'SEP',
      '10': 'OCT',
      '11': 'NOV',
      '12': 'DEC',
      'other': '',
    });
    return '$day $_temp0';
  }

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get mergeVolumes => 'Merge volumes';

  @override
  String get mergeVolumesDetail =>
      'Volumes ticked together become one EPUB, each volume a section of its contents.';

  @override
  String get theme => 'Theme';

  @override
  String get themeDetail => 'System follows the phone\'s dark mode.';

  @override
  String get themeSystem => 'SYSTEM';

  @override
  String get themeLight => 'LIGHT';

  @override
  String get themeDark => 'DARK';

  @override
  String get language => 'Language';

  @override
  String get languageDetail =>
      'The app\'s own words. Book titles and the site stay in Chinese.';

  @override
  String get about => 'About';

  @override
  String get aboutDetail => 'What the app is built on, and its licences.';

  @override
  String get aboutTitle => 'ABOUT';

  @override
  String get aboutWhat =>
      'Browse linovelib, download volumes as EPUB with their illustrations in place, and read them in your own reader.';

  @override
  String get aboutDownloadOnly =>
      'Bunko is made for downloading. Read the saved volumes in your reader app; reading chapters on the site inside Bunko is not recommended, as the site can stop the page scrolling when it notices its ads are blocked.';

  @override
  String get aboutBuiltOn =>
      'Built on bili_novel_packer by Montaro2017 (MIT licence), which reads the site, restores the paragraph order and builds each EPUB.';

  @override
  String get aboutPersonal =>
      'Downloads are for your own reading. Please do not share the files.';

  @override
  String get openSourceLicences => 'OPEN SOURCE LICENCES';

  @override
  String noticeDownloading(String title) {
    return 'Downloading $title';
  }

  @override
  String noticeMoreWaiting(int percent, int count) {
    return '$percent% · $count more waiting';
  }

  @override
  String volumeNumber(String number) {
    return 'Volume $number';
  }

  @override
  String get libraryFolder => 'Library folder';

  @override
  String get libraryFolderDetail =>
      'Downloads are saved here, and Library lists the EPUBs in it. After reinstalling Bunko, pick this folder again to bring back saved volumes.';

  @override
  String get changeFolder => 'CHANGE';

  @override
  String get useDefaultFolder => 'USE DEFAULT';
}
