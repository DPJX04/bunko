import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../models/result.dart';
import '../services/local_store.dart';

/// The app's one [SettingsRepository].
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(LocalStore()),
);

/// Keeps the Settings screen's choices on the phone between app starts.
class SettingsRepository {
  SettingsRepository(this._store);

  final LocalStore _store;

  /// Where the merge choice is stored, as 'true' or 'false'.
  static const _mergeKey = 'merge_volumes';

  /// Where the theme is stored, by name: 'system', 'light' or 'dark'.
  static const _themeKey = 'theme';

  /// Where the language is stored, by code: 'en' or 'zh'.
  static const _languageKey = 'language';

  /// Where the library folder is stored, as a tree URI; empty means the
  /// default folder.
  static const _folderKey = 'library_folder';

  /// Reads the stored settings; anything never stored, or stored in a form
  /// this version does not know, keeps its default.
  Future<Result<AppSettings>> load() async {
    final merge = await _store.readString(_mergeKey);
    final theme = await _store.readString(_themeKey);
    final language = await _store.readString(_languageKey);
    final folder = await _store.readString(_folderKey);
    return switch ((merge, theme, language, folder)) {
      (
        Ok(data: final merge),
        Ok(data: final theme),
        Ok(data: final language),
        Ok(data: final folder),
      ) =>
        Ok(
          AppSettings(
            mergeVolumes: merge == 'true',
            theme: ThemeChoice.values.firstWhere(
              (choice) => choice.name == theme,
              orElse: () => ThemeChoice.system,
            ),
            language: AppLanguage.values.firstWhere(
              (choice) => choice.code == language,
              orElse: () => AppLanguage.english,
            ),
            libraryFolder: (folder ?? '').isEmpty ? null : folder,
          ),
        ),
      (Err(:final message), _, _, _) ||
      (_, Err(:final message), _, _) ||
      (_, _, Err(:final message), _) ||
      (_, _, _, Err(:final message)) => Err(message),
    };
  }

  /// Stores [settings], replacing what was there. Returns the first
  /// failure, if any.
  Future<Result<void>> save(AppSettings settings) async {
    final writes = [
      await _store.writeString(_mergeKey, '${settings.mergeVolumes}'),
      await _store.writeString(_themeKey, settings.theme.name),
      await _store.writeString(_languageKey, settings.language.code),
      await _store.writeString(_folderKey, settings.libraryFolder ?? ''),
    ];
    return writes.firstWhere(
      (write) => write is Err,
      orElse: () => const Ok(null),
    );
  }
}
