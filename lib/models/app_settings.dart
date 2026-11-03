/// The owner's choices on the Settings screen.
class AppSettings {
  const AppSettings({
    this.mergeVolumes = false,
    this.theme = ThemeChoice.system,
    this.language = AppLanguage.english,
    this.libraryFolder,
  });

  /// True when ticking several volumes in the picker makes one EPUB of
  /// them instead of one EPUB each.
  final bool mergeVolumes;

  /// Light, dark, or whatever the phone's dark mode says.
  final ThemeChoice theme;

  /// The language of the app's own words. Book titles and the site stay
  /// in Chinese either way.
  final AppLanguage language;

  /// The folder the owner picked for the library, as an Android tree URI:
  /// downloads are saved there and Library lists the EPUBs in it. Null
  /// means the default, Download/LightNovel.
  final String? libraryFolder;

  /// A copy with the given choices changed. Pass null as [libraryFolder]
  /// to go back to the default folder.
  AppSettings copyWith({
    bool? mergeVolumes,
    ThemeChoice? theme,
    AppLanguage? language,
    Object? libraryFolder = _unchanged,
  }) {
    return AppSettings(
      mergeVolumes: mergeVolumes ?? this.mergeVolumes,
      theme: theme ?? this.theme,
      language: language ?? this.language,
      libraryFolder: identical(libraryFolder, _unchanged)
          ? this.libraryFolder
          : libraryFolder as String?,
    );
  }

  /// Marks a [copyWith] argument left out, as null means the default.
  static const _unchanged = Object();
}

/// Which plate the app shows.
enum ThemeChoice { system, light, dark }

/// The languages the app's own words come in, with their language codes.
enum AppLanguage {
  english('en'),
  chinese('zh');

  const AppLanguage(this.code);

  /// The language code, such as 'zh', as Flutter's Locale takes it.
  final String code;
}
