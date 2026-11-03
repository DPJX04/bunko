import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/models/app_settings.dart';
import 'package:light_novel_downloader/repositories/settings_repository.dart';
import 'package:light_novel_downloader/state/settings_state.dart';

import '../support/fakes.dart';

void main() {
  late MemoryStore store;

  /// A fresh app run over the same stored values.
  ProviderContainer app() {
    final container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(store)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => store = MemoryStore());

  test('merging volumes starts off', () async {
    final settings = await app().read(settingsProvider.future);

    expect(settings.mergeVolumes, isFalse);
  });

  test('turning merge on shows at once and survives a restart', () async {
    final first = app();
    await first.read(settingsProvider.future);

    await first.read(settingsProvider.notifier).setMergeVolumes(true);

    expect(first.read(settingsProvider).value!.mergeVolumes, isTrue);
    final restarted = await app().read(settingsProvider.future);
    expect(restarted.mergeVolumes, isTrue);
  });

  test(
    'the theme follows the phone and the language is English at first',
    () async {
      final settings = await app().read(settingsProvider.future);

      expect(settings.theme, ThemeChoice.system);
      expect(settings.language, AppLanguage.english);
    },
  );

  test('a theme picked shows at once and survives a restart', () async {
    final first = app();
    await first.read(settingsProvider.future);

    await first.read(settingsProvider.notifier).setTheme(ThemeChoice.light);

    expect(first.read(settingsProvider).value!.theme, ThemeChoice.light);
    final restarted = await app().read(settingsProvider.future);
    expect(restarted.theme, ThemeChoice.light);
  });

  test(
    'a language picked survives a restart and keeps the other settings',
    () async {
      final first = app();
      await first.read(settingsProvider.future);
      await first.read(settingsProvider.notifier).setMergeVolumes(true);
      await first.read(settingsProvider.notifier).setTheme(ThemeChoice.dark);

      await first
          .read(settingsProvider.notifier)
          .setLanguage(AppLanguage.chinese);

      final restarted = await app().read(settingsProvider.future);
      expect(restarted.language, AppLanguage.chinese);
      expect(restarted.theme, ThemeChoice.dark);
      expect(restarted.mergeVolumes, isTrue);
    },
  );

  test(
    'a stored value the app does not know falls back to the default',
    () async {
      store.values['theme'] = 'purple';
      store.values['language'] = 'fr';

      final settings = await app().read(settingsProvider.future);

      expect(settings.theme, ThemeChoice.system);
      expect(settings.language, AppLanguage.english);
    },
  );
}
