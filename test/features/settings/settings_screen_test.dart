import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/features/settings/about_screen.dart';
import 'package:light_novel_downloader/features/settings/settings_screen.dart';
import 'package:light_novel_downloader/models/app_settings.dart';
import 'package:light_novel_downloader/repositories/downloaded_volume_repository.dart';
import 'package:light_novel_downloader/repositories/settings_repository.dart';
import 'package:light_novel_downloader/state/settings_state.dart';
import 'package:light_novel_downloader/widgets/app_theme.dart';

import '../../support/fakes.dart';

/// Whether TalkBack hears the plate labelled [label] as the one picked.
bool selected(WidgetTester tester, String label) {
  return isSemantics(
    isSelected: true,
  ).matches(tester.getSemantics(find.text(label)), {});
}

void main() {
  late ProviderContainer container;
  late int aboutTaps;
  late FakeStorage storage;

  Future<void> show(WidgetTester tester) async {
    // The test phone's size, 366 by 800 dp, so every row fits on screen.
    tester.view.physicalSize = const Size(1280, 2800);
    tester.view.devicePixelRatio = 3.5;
    addTearDown(tester.view.reset);
    aboutTaps = 0;
    storage = FakeStorage();
    final store = MemoryStore();
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(SettingsRepository(store)),
        downloadedVolumeRepositoryProvider.overrideWithValue(
          DownloadedVolumeRepository(storage, store),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.dark,
          home: SettingsScreen(onAbout: () => aboutTaps++),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('merging starts off, and a tap turns it on', (tester) async {
    await show(tester);
    final box = find.widgetWithText(CheckboxListTile, 'Merge volumes');
    expect(tester.widget<CheckboxListTile>(box).value, isFalse);

    await tester.tap(box);
    await tester.pumpAndSettle();

    expect(tester.widget<CheckboxListTile>(box).value, isTrue);
    expect(container.read(settingsProvider).value!.mergeVolumes, isTrue);
  });

  testWidgets('the theme starts on System, and a tap picks Dark', (
    tester,
  ) async {
    await show(tester);
    expect(selected(tester, 'SYSTEM'), isTrue);

    await tester.tap(find.text('DARK'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).value!.theme, ThemeChoice.dark);
    expect(selected(tester, 'DARK'), isTrue);
    expect(selected(tester, 'SYSTEM'), isFalse);
  });

  testWidgets('a tap on 中文 switches the language', (tester) async {
    await show(tester);

    await tester.tap(find.text('中文'));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsProvider).value!.language,
      AppLanguage.chinese,
    );
  });

  testWidgets('the library folder starts as Download/LightNovel', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('Download/LightNovel'), findsOneWidget);
    expect(find.text('USE DEFAULT'), findsNothing);
  });

  testWidgets('CHANGE keeps the folder picked, and USE DEFAULT undoes it', (
    tester,
  ) async {
    await show(tester);
    storage.picked =
        'content://com.android.externalstorage.documents/tree/'
        'primary%3ADocuments%2FNovels';

    await tester.ensureVisible(find.text('CHANGE'));
    await tester.tap(find.text('CHANGE'));
    await tester.pumpAndSettle();

    expect(
      container.read(settingsProvider).value!.libraryFolder,
      storage.picked,
    );
    expect(find.text('Documents/Novels'), findsOneWidget);
    await tester.ensureVisible(find.text('USE DEFAULT'));
    await tester.tap(find.text('USE DEFAULT'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).value!.libraryFolder, isNull);
  });

  testWidgets('backing out of the picker changes nothing', (tester) async {
    await show(tester);

    await tester.ensureVisible(find.text('CHANGE'));
    await tester.tap(find.text('CHANGE'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).value!.libraryFolder, isNull);
  });

  testWidgets('About opens the About screen', (tester) async {
    await show(tester);

    await tester.scrollUntilVisible(find.text('About'), 100);
    await tester.pumpAndSettle();
    await tester.tap(find.text('About'));

    expect(aboutTaps, 1);
  });

  testWidgets('the About screen opens the licence page', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const AboutScreen()),
    );

    expect(find.textContaining('bili_novel_packer'), findsOneWidget);
    expect(find.textContaining('made for downloading'), findsOneWidget);
    await tester.tap(find.text('OPEN SOURCE LICENCES'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
