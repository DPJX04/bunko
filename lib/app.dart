import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'l10n/l10n.dart';
import 'models/app_settings.dart';
import 'routing/app_router.dart';
import 'state/download_records_state.dart';
import 'state/settings_state.dart';
import 'widgets/app_theme.dart';

/// Root widget: the router and the light and dark plates, in the theme and
/// language picked in Settings, unless a screenshot build forces a theme.
///
/// At start, each time the app comes back to the front, and when the
/// library folder changes, it matches Library to the EPUBs in that folder,
/// so a file deleted meanwhile leaves and a file found there joins.
class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _syncLibrary);
    _syncLibrary();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Matches Library to the EPUBs in the library folder.
  void _syncLibrary() => ref.read(downloadRecordsProvider.notifier).sync();

  @override
  Widget build(BuildContext context) {
    ref.listen(
      settingsProvider.select((settings) => settings.value?.libraryFolder),
      (before, now) {
        if (before != now) _syncLibrary();
      },
    );
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final chinese = settings.language == AppLanguage.chinese;
    return MaterialApp.router(
      title: 'Bunko',
      debugShowCheckedModeBanner: false,
      theme: chinese ? AppTheme.lightChinese : AppTheme.light,
      darkTheme: chinese ? AppTheme.darkChinese : AppTheme.dark,
      themeMode: _themeMode(settings.theme),
      locale: Locale(settings.language.code),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: appRouter,
    );
  }

  /// The plate for [choice], unless [AppConfig.forcedTheme] forces one.
  ThemeMode _themeMode(ThemeChoice choice) {
    return switch ((AppConfig.forcedTheme, choice)) {
      ('light', _) => ThemeMode.light,
      ('dark', _) => ThemeMode.dark,
      (_, ThemeChoice.light) => ThemeMode.light,
      (_, ThemeChoice.dark) => ThemeMode.dark,
      (_, ThemeChoice.system) => ThemeMode.system,
    };
  }
}
