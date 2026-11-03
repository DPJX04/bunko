import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../l10n/l10n.dart';
import '../../models/app_settings.dart';
import '../../models/result.dart';
import '../../repositories/downloaded_volume_repository.dart';
import '../../state/settings_state.dart';
import 'widgets/plate_choice.dart';

/// The Settings screen, opened from the Library tab: the merge choice, the
/// library folder, the theme, the language and the way to About.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.onAbout});

  /// Opens the About screen.
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final change = ref.read(settingsProvider.notifier);
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final ash = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // A checkbox row, like the picker's, rather than a pill switch:
          // controls in this world keep their 2 dp corners.
          CheckboxListTile(
            value: settings.mergeVolumes,
            onChanged: (on) =>
                _store(context, change.setMergeVolumes(on ?? false)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsetsDirectional.only(
              start: 16,
              end: 24,
            ),
            title: Text(l10n.mergeVolumes, style: text.titleSmall),
            subtitle: Text(
              l10n.mergeVolumesDetail,
              style: text.bodyMedium?.copyWith(color: ash),
            ),
          ),
          const Divider(height: 1),
          _FolderSection(
            folder: settings.libraryFolder,
            onChange: () => _pickFolder(context, ref),
            onUseDefault: () => _store(context, change.setLibraryFolder(null)),
          ),
          const Divider(height: 1),
          _ChoiceSection(
            title: l10n.theme,
            detail: l10n.themeDetail,
            choice: PlateChoice<ThemeChoice>(
              options: [
                (ThemeChoice.system, l10n.themeSystem),
                (ThemeChoice.light, l10n.themeLight),
                (ThemeChoice.dark, l10n.themeDark),
              ],
              picked: settings.theme,
              onPicked: (theme) => _store(context, change.setTheme(theme)),
            ),
          ),
          const Divider(height: 1),
          _ChoiceSection(
            title: l10n.language,
            detail: l10n.languageDetail,
            // Each language is named in itself, so it can be found from
            // either one.
            choice: PlateChoice<AppLanguage>(
              options: const [
                (AppLanguage.english, 'ENGLISH'),
                (AppLanguage.chinese, '中文'),
              ],
              picked: settings.language,
              onPicked: (language) =>
                  _store(context, change.setLanguage(language)),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsetsDirectional.only(
              start: 24,
              end: 16,
            ),
            title: Text(l10n.about, style: text.titleSmall),
            subtitle: Text(
              l10n.aboutDetail,
              style: text.bodyMedium?.copyWith(color: ash),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: ash),
            onTap: onAbout,
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  /// Opens Android's folder picker and keeps the folder picked. Backing
  /// out changes nothing.
  Future<void> _pickFolder(BuildContext context, WidgetRef ref) async {
    final folder = await ref
        .read(downloadedVolumeRepositoryProvider)
        .pickFolder();
    if (folder == null || !context.mounted) return;
    await _store(
      context,
      ref.read(settingsProvider.notifier).setLibraryFolder(folder),
    );
  }

  /// Waits for a setting to be stored; if the phone cannot store it, says
  /// so. The choice still holds until the app closes.
  Future<void> _store(BuildContext context, Future<Result<void>> saving) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final saved = await saving;
    if (saved is Err<void>) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizedError(l10n, saved.message))),
      );
    }
  }
}

/// The library folder: its name, one ash sentence, the folder's path, and
/// CHANGE, with USE DEFAULT while a picked folder is in use.
class _FolderSection extends StatelessWidget {
  const _FolderSection({
    required this.folder,
    required this.onChange,
    required this.onUseDefault,
  });

  /// The picked folder's tree URI, or null for the default.
  final String? folder;
  final VoidCallback onChange;
  final VoidCallback onUseDefault;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final ash = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.libraryFolder, style: text.titleSmall),
          const SizedBox(height: 4),
          Text(
            l10n.libraryFolderDetail,
            style: text.bodyMedium?.copyWith(color: ash),
          ),
          const SizedBox(height: 12),
          Text(_path(folder), style: text.bodyMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onChange,
                child: Text(l10n.changeFolder),
              ),
              if (folder != null)
                TextButton(
                  onPressed: onUseDefault,
                  child: Text(l10n.useDefaultFolder),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// The folder as a path, such as 'Download/LightNovel': the part of the
  /// tree URI after the storage name, 'primary:Download/LightNovel'.
  static String _path(String? folder) {
    if (folder == null) return 'Download/${AppConfig.downloadFolder}';
    final id = Uri.decodeComponent(folder.split('/tree/').last);
    final colon = id.indexOf(':');
    return colon < 0 ? id : id.substring(colon + 1);
  }
}

/// A setting picked from a few plates: its name, one ash sentence, then
/// the plates.
class _ChoiceSection extends StatelessWidget {
  const _ChoiceSection({
    required this.title,
    required this.detail,
    required this.choice,
  });

  final String title;
  final String detail;
  final Widget choice;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ash = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: text.titleSmall),
          const SizedBox(height: 4),
          Text(detail, style: text.bodyMedium?.copyWith(color: ash)),
          const SizedBox(height: 16),
          choice,
        ],
      ),
    );
  }
}
