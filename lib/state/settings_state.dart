import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../models/result.dart';
import '../repositories/settings_repository.dart';

/// The owner's settings. The Settings screen changes them; the volume
/// picker reads the merge choice, and the app root the theme and language.
final settingsProvider = AsyncNotifierProvider<SettingsState, AppSettings>(
  SettingsState.new,
);

/// Holds the settings loaded from the phone, and stores changes.
class SettingsState extends AsyncNotifier<AppSettings> {
  SettingsRepository get _repository => ref.read(settingsRepositoryProvider);

  /// Loads the stored settings. If they cannot be read, the defaults hold.
  @override
  Future<AppSettings> build() async {
    final loaded = await _repository.load();
    return switch (loaded) {
      Ok(:final data) => data,
      Err() => const AppSettings(),
    };
  }

  /// Turns merging ticked volumes into one EPUB on or off, and stores it.
  /// Returns Err when the phone could not store it; the choice still holds
  /// until the app closes.
  Future<Result<void>> setMergeVolumes(bool merge) {
    return _change((settings) => settings.copyWith(mergeVolumes: merge));
  }

  /// Switches the app to [theme] at once, and stores it. Returns Err as
  /// [setMergeVolumes] does.
  Future<Result<void>> setTheme(ThemeChoice theme) {
    return _change((settings) => settings.copyWith(theme: theme));
  }

  /// Switches the app's own words to [language] at once, and stores it.
  /// Returns Err as [setMergeVolumes] does.
  Future<Result<void>> setLanguage(AppLanguage language) {
    return _change((settings) => settings.copyWith(language: language));
  }

  /// Makes [folder] the library folder, or the default Download/LightNovel
  /// when null, and stores it. Returns Err as [setMergeVolumes] does.
  Future<Result<void>> setLibraryFolder(String? folder) {
    return _change((settings) => settings.copyWith(libraryFolder: folder));
  }

  /// Applies [change] to the loaded settings, shows the result, and stores
  /// all of it.
  Future<Result<void>> _change(
    AppSettings Function(AppSettings settings) change,
  ) async {
    final settings = change(await future);
    state = AsyncData(settings);
    return _repository.save(settings);
  }
}
