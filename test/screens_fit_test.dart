// Renders every screen of the app's own chrome on the test phone's size,
// in both themes, both languages and at a large system font, and fails on
// any overflow. Large font sizes must not break any screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:light_novel_downloader/features/download/download_queue_controller.dart';
import 'package:light_novel_downloader/features/download/download_task.dart';
import 'package:light_novel_downloader/features/download/downloads_screen.dart';
import 'package:light_novel_downloader/features/download/volume_picker_sheet.dart';
import 'package:light_novel_downloader/features/library/library_screen.dart';
import 'package:light_novel_downloader/features/settings/about_screen.dart';
import 'package:light_novel_downloader/features/settings/settings_screen.dart';
import 'package:light_novel_downloader/l10n/l10n.dart';
import 'package:light_novel_downloader/models/volume.dart';
import 'package:light_novel_downloader/repositories/downloaded_volume_repository.dart';
import 'package:light_novel_downloader/routing/app_shell.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';
import 'package:light_novel_downloader/widgets/app_theme.dart';

import 'support/fakes.dart';
import 'support/fonts.dart';

/// A queue frozen at the given rows.
class FrozenQueue extends DownloadQueueController {
  FrozenQueue(this.rows);

  final List<DownloadTask> rows;

  @override
  List<DownloadTask> build() => rows;
}

/// One row of each kind, with long titles, as the Downloads tab may show.
List<DownloadTask> everyKindOfRow() {
  DownloadTask row(int id, DownloadStatus status, {int done = 0}) {
    return DownloadTask(
      id: id,
      volumes: [
        Volume(
          bookId: '114',
          number: id,
          title: '无赖勇者的鬼畜美学 $id 是的，这是魔装少女',
          chapterCount: 9,
        ),
      ],
      bookTitle: '无赖勇者的鬼畜美学',
      status: status,
      chaptersDone: done,
      chaptersTotal: 9,
      errorMessage: status == DownloadStatus.failed ? noInternet : null,
    );
  }

  return [
    row(1, DownloadStatus.done, done: 9),
    row(2, DownloadStatus.downloading, done: 4),
    row(3, DownloadStatus.waiting),
    row(4, DownloadStatus.failed),
  ];
}

void main() {
  for (final language in ['en', 'zh']) {
    for (final dark in [true, false]) {
      for (final scale in [1.0, 1.5]) {
        final label =
            '$language, ${dark ? 'dark' : 'light'} at font scale $scale';
        final l10n = lookupAppLocalizations(Locale(language));
        final chinese = language == 'zh';

        /// Sets the phone's size and font scale, and loads the real font.
        Future<void> phone(WidgetTester tester) async {
          await tester.runAsync(loadArchivo);
          // The Honor test phone: 1280 by 2800 pixels at density 560.
          tester.view.physicalSize = const Size(1280, 2800);
          tester.view.devicePixelRatio = 3.5;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.reset);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }

        /// Shows [home] inside the app's theme over [overrides].
        Future<void> show(
          WidgetTester tester,
          Widget home, {
          List<Override> overrides = const [],
        }) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [...overrides],
              child: MaterialApp(
                theme: switch ((dark, chinese)) {
                  (true, true) => AppTheme.darkChinese,
                  (true, false) => AppTheme.dark,
                  (false, true) => AppTheme.lightChinese,
                  (false, false) => AppTheme.light,
                },
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: home,
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        testWidgets('Downloads fits, $label', (tester) async {
          await phone(tester);
          await show(
            tester,
            DownloadsScreen(onBrowse: () {}),
            overrides: [
              downloadQueueProvider.overrideWith(
                () => FrozenQueue(everyKindOfRow()),
              ),
            ],
          );

          await tester.tap(find.byTooltip(l10n.cancelDownloadTooltip).first);
          await tester.pumpAndSettle();
          expect(find.text(l10n.cancelDownload), findsWidgets);
        });

        testWidgets('the picker fits, $label', (tester) async {
          await phone(tester);
          final world = FakeWorld(volumeCount: 3);
          addTearDown(world.dispose);
          await tester.runAsync(() async {
            final repository = DownloadedVolumeRepository(
              world.storage,
              world.store,
            );
            await repository.addRecord(record(2));
          });
          await show(
            tester,
            Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => VolumePickerSheet(
                      bookId: '5330',
                      bookTitle: '酒醉就旅行的今里小姐',
                      onViewDownloads: () {},
                    ),
                  ),
                  child: const Text('OPEN'),
                ),
              ),
            ),
            overrides: world.overrides,
          );

          await tester.tap(find.text('OPEN'));
          await tester.pumpAndSettle();
          expect(find.text(l10n.selectAll), findsOneWidget);
        });

        testWidgets('the Library fits, $label', (tester) async {
          await phone(tester);
          final world = FakeWorld();
          addTearDown(world.dispose);
          await tester.runAsync(() async {
            final repository = DownloadedVolumeRepository(
              world.storage,
              world.store,
            );
            for (final n in [1, 2, 3]) {
              await repository.addRecord(record(n));
            }
          });
          await show(
            tester,
            LibraryScreen(onBrowse: () {}, onSettings: () {}),
            overrides: world.overrides,
          );

          expect(find.text(l10n.volumeCount(3)), findsOneWidget);
        });

        testWidgets('Settings and About fit, $label', (tester) async {
          await phone(tester);
          final world = FakeWorld();
          addTearDown(world.dispose);
          await show(
            tester,
            SettingsScreen(onAbout: () {}),
            overrides: world.overrides,
          );
          await show(tester, const AboutScreen(), overrides: world.overrides);

          expect(find.text(l10n.openSourceLicences), findsOneWidget);
        });

        testWidgets('the tab bar fits, $label', (tester) async {
          await phone(tester);
          final router = GoRouter(
            initialLocation: '/a',
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (context, state, shell) => AppShell(shell: shell),
                branches: [
                  for (final path in ['/a', '/b', '/c'])
                    StatefulShellBranch(
                      routes: [
                        GoRoute(
                          path: path,
                          builder: (_, _) => const SizedBox.expand(),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                downloadQueueProvider.overrideWith(
                  () => FrozenQueue(everyKindOfRow()),
                ),
              ],
              child: MaterialApp.router(
                theme: switch ((dark, chinese)) {
                  (true, true) => AppTheme.darkChinese,
                  (true, false) => AppTheme.dark,
                  (false, true) => AppTheme.lightChinese,
                  (false, false) => AppTheme.light,
                },
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text(l10n.tabDownloads), findsWidgets);
        });
      }
    }
  }
}
