import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Navigation bar label of the Browse tab.
  ///
  /// In en, this message translates to:
  /// **'BROWSE'**
  String get tabBrowse;

  /// Navigation bar label of the Downloads tab, and its screen title.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOADS'**
  String get tabDownloads;

  /// Navigation bar label of the Library tab, and its screen title.
  ///
  /// In en, this message translates to:
  /// **'LIBRARY'**
  String get tabLibrary;

  /// What TalkBack reads for the count badge on the Downloads tab.
  ///
  /// In en, this message translates to:
  /// **'{count} in the queue'**
  String queueCount(int count);

  /// Tooltip of the Home button on the Browse strip.
  ///
  /// In en, this message translates to:
  /// **'Site home'**
  String get browseHome;

  /// Tooltip of the Back button on the Browse strip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get browseBack;

  /// Tooltip of the Download button on a book page.
  ///
  /// In en, this message translates to:
  /// **'Download volumes'**
  String get downloadVolumesTooltip;

  /// The Download button on a book page, and the picker button with nothing ticked.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD'**
  String get download;

  /// Button that tries a failed page or download again.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get retry;

  /// Button that opens a saved volume in a reader app.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get open;

  /// Snackbar button that goes to the Downloads tab.
  ///
  /// In en, this message translates to:
  /// **'VIEW'**
  String get view;

  /// Empty state button that goes to the Browse tab.
  ///
  /// In en, this message translates to:
  /// **'BROWSE BOOKS'**
  String get browseBooks;

  /// No description provided for @errorPageDidNotLoad.
  ///
  /// In en, this message translates to:
  /// **'The page did not load. Tap Retry.'**
  String get errorPageDidNotLoad;

  /// No description provided for @errorNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check Wi‑Fi and tap Retry.'**
  String get errorNoInternet;

  /// No description provided for @errorTooSlow.
  ///
  /// In en, this message translates to:
  /// **'The site took too long to answer. Tap Retry.'**
  String get errorTooSlow;

  /// No description provided for @errorBlocked.
  ///
  /// In en, this message translates to:
  /// **'The site blocked the request. Open the book page in Browse once, then tap Retry.'**
  String get errorBlocked;

  /// No description provided for @errorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Wait a minute, then tap Retry.'**
  String get errorTooManyRequests;

  /// No description provided for @errorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This page was not found on the site.'**
  String get errorNotFound;

  /// No description provided for @errorPageChanged.
  ///
  /// In en, this message translates to:
  /// **'The site page looked different than expected. The app may need an update.'**
  String get errorPageChanged;

  /// No description provided for @errorCouldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save the file. Check free space on the phone.'**
  String get errorCouldNotSave;

  /// No description provided for @errorFileMissing.
  ///
  /// In en, this message translates to:
  /// **'This file is no longer in Download/LightNovel. Download the volume again.'**
  String get errorFileMissing;

  /// No description provided for @errorNoReader.
  ///
  /// In en, this message translates to:
  /// **'No app on this phone opens EPUB files. Install a reader such as eBoox.'**
  String get errorNoReader;

  /// No description provided for @errorCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled.'**
  String get errorCancelled;

  /// No description provided for @errorSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Tap Retry.'**
  String get errorSomethingWentWrong;

  /// Downloads app bar button that removes saved rows.
  ///
  /// In en, this message translates to:
  /// **'CLEAR'**
  String get clear;

  /// No description provided for @clearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove saved rows. The files stay.'**
  String get clearTooltip;

  /// No description provided for @downloadsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No downloads running'**
  String get downloadsEmptyTitle;

  /// No description provided for @downloadsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Open a book in Browse and tap Download. Volumes wait here in order and download one at a time.'**
  String get downloadsEmptyMessage;

  /// Picker button with volumes ticked.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{DOWNLOAD 1 VOLUME} other{DOWNLOAD {count} VOLUMES}}'**
  String downloadVolumes(int count);

  /// Picker button with several volumes ticked and merging on.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD {count} AS ONE EPUB'**
  String downloadMerged(int count);

  /// Picker heading when the page gave no book title.
  ///
  /// In en, this message translates to:
  /// **'This book'**
  String get thisBook;

  /// The book id on the site, under the picker heading.
  ///
  /// In en, this message translates to:
  /// **'LINOVELIB #{bookId}'**
  String siteId(String bookId);

  /// No description provided for @authorAndSiteId.
  ///
  /// In en, this message translates to:
  /// **'{author} · LINOVELIB #{bookId}'**
  String authorAndSiteId(String author, String bookId);

  /// No description provided for @readingContents.
  ///
  /// In en, this message translates to:
  /// **'Reading the table of contents.'**
  String get readingContents;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'SELECT ALL'**
  String get selectAll;

  /// A volume row in the picker.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 CHAPTER} other{{count} CHAPTERS}}'**
  String chapterCount(int count);

  /// Follows the chapter count of a volume already waiting or downloading.
  ///
  /// In en, this message translates to:
  /// **' · IN DOWNLOADS'**
  String get markInDownloads;

  /// Follows the chapter count of a volume already saved.
  ///
  /// In en, this message translates to:
  /// **' · SAVED'**
  String get markSaved;

  /// Question of the cancel dialog, with the volume title.
  ///
  /// In en, this message translates to:
  /// **'Cancel {title}?'**
  String cancelTitle(String title);

  /// No description provided for @cancelRunning.
  ///
  /// In en, this message translates to:
  /// **'It stops before its next chapter, and nothing is saved.'**
  String get cancelRunning;

  /// No description provided for @cancelWaiting.
  ///
  /// In en, this message translates to:
  /// **'It leaves the queue before it starts.'**
  String get cancelWaiting;

  /// No description provided for @cancelDownload.
  ///
  /// In en, this message translates to:
  /// **'CANCEL DOWNLOAD'**
  String get cancelDownload;

  /// Dialog button that keeps the download.
  ///
  /// In en, this message translates to:
  /// **'KEEP'**
  String get keep;

  /// No description provided for @cancelDownloadTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get cancelDownloadTooltip;

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'WAITING'**
  String get statusWaiting;

  /// No description provided for @statusSaved.
  ///
  /// In en, this message translates to:
  /// **'SAVED'**
  String get statusSaved;

  /// No description provided for @statusFailed.
  ///
  /// In en, this message translates to:
  /// **'FAILED'**
  String get statusFailed;

  /// No description provided for @savedToFolder.
  ///
  /// In en, this message translates to:
  /// **'Saved to Download/LightNovel'**
  String get savedToFolder;

  /// No description provided for @volumesAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 volume added} other{{count} volumes added}}'**
  String volumesAdded(int count);

  /// No description provided for @volumesAddedMerged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 volume added as one EPUB} other{{count} volumes added as one EPUB}}'**
  String volumesAddedMerged(int count);

  /// Snackbar when a volume is saved.
  ///
  /// In en, this message translates to:
  /// **'Saved {title}'**
  String savedVolume(String title);

  /// Tooltip of the Settings button on Library.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @libraryEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No volumes yet'**
  String get libraryEmptyTitle;

  /// No description provided for @libraryEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Every volume you download is saved to Download/LightNovel and listed here by book, ready to open in your reader. After a reinstall, pick that folder in Settings → Library folder to bring them back.'**
  String get libraryEmptyMessage;

  /// Under a book title on Library.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 VOLUME} other{{count} VOLUMES}}'**
  String volumeCount(int count);

  /// What TalkBack says a Library row does.
  ///
  /// In en, this message translates to:
  /// **'Opens in your reader'**
  String get opensInReader;

  /// What TalkBack says a folded book header does.
  ///
  /// In en, this message translates to:
  /// **'Shows its volumes'**
  String get showVolumes;

  /// What TalkBack says an open book header does.
  ///
  /// In en, this message translates to:
  /// **'Hides its volumes'**
  String get hideVolumes;

  /// Under a volume on Library, with the day it was saved.
  ///
  /// In en, this message translates to:
  /// **'SAVED {date}'**
  String savedOn(String date);

  /// A short date, such as 3 NOV. month is 1 to 12.
  ///
  /// In en, this message translates to:
  /// **'{day} {month, select, 1{JAN} 2{FEB} 3{MAR} 4{APR} 5{MAY} 6{JUN} 7{JUL} 8{AUG} 9{SEP} 10{OCT} 11{NOV} 12{DEC} other{}}'**
  String dayMonth(String day, String month);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @mergeVolumes.
  ///
  /// In en, this message translates to:
  /// **'Merge volumes'**
  String get mergeVolumes;

  /// No description provided for @mergeVolumesDetail.
  ///
  /// In en, this message translates to:
  /// **'Volumes ticked together become one EPUB, each volume a section of its contents.'**
  String get mergeVolumesDetail;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDetail.
  ///
  /// In en, this message translates to:
  /// **'System follows the phone\'s dark mode.'**
  String get themeDetail;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'LIGHT'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'DARK'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDetail.
  ///
  /// In en, this message translates to:
  /// **'The app\'s own words. Book titles and the site stay in Chinese.'**
  String get languageDetail;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutDetail.
  ///
  /// In en, this message translates to:
  /// **'What the app is built on, and its licences.'**
  String get aboutDetail;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get aboutTitle;

  /// No description provided for @aboutWhat.
  ///
  /// In en, this message translates to:
  /// **'Browse linovelib, download volumes as EPUB with their illustrations in place, and read them in your own reader.'**
  String get aboutWhat;

  /// About screen: the app is for downloading, not for reading on the site.
  ///
  /// In en, this message translates to:
  /// **'Bunko is made for downloading. Read the saved volumes in your reader app; reading chapters on the site inside Bunko is not recommended, as the site can stop the page scrolling when it notices its ads are blocked.'**
  String get aboutDownloadOnly;

  /// No description provided for @aboutBuiltOn.
  ///
  /// In en, this message translates to:
  /// **'Built on bili_novel_packer by Montaro2017 (MIT licence), which reads the site, restores the paragraph order and builds each EPUB.'**
  String get aboutBuiltOn;

  /// No description provided for @aboutPersonal.
  ///
  /// In en, this message translates to:
  /// **'Downloads are for your own reading. Please do not share the files.'**
  String get aboutPersonal;

  /// No description provided for @openSourceLicences.
  ///
  /// In en, this message translates to:
  /// **'OPEN SOURCE LICENCES'**
  String get openSourceLicences;

  /// Title of the download notification.
  ///
  /// In en, this message translates to:
  /// **'Downloading {title}'**
  String noticeDownloading(String title);

  /// Text of the download notification.
  ///
  /// In en, this message translates to:
  /// **'{percent}% · {count} more waiting'**
  String noticeMoreWaiting(int percent, int count);

  /// A volume on Library whose name is its book title and a number, such as Volume 4.5.
  ///
  /// In en, this message translates to:
  /// **'Volume {number}'**
  String volumeNumber(String number);

  /// Settings: the folder downloads go to and Library lists.
  ///
  /// In en, this message translates to:
  /// **'Library folder'**
  String get libraryFolder;

  /// No description provided for @libraryFolderDetail.
  ///
  /// In en, this message translates to:
  /// **'Downloads are saved here, and Library lists the EPUBs in it. After reinstalling Bunko, pick this folder again to bring back saved volumes.'**
  String get libraryFolderDetail;

  /// Opens Android's folder picker for the library folder.
  ///
  /// In en, this message translates to:
  /// **'CHANGE'**
  String get changeFolder;

  /// Goes back to Download/LightNovel as the library folder.
  ///
  /// In en, this message translates to:
  /// **'USE DEFAULT'**
  String get useDefaultFolder;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
