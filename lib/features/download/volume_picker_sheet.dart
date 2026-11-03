import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/book.dart';
import '../../models/volume.dart';
import '../../state/settings_state.dart';
import '../../widgets/emission_line.dart';
import '../../widgets/error_view.dart';
import '../../widgets/motion.dart';
import '../../widgets/spectrum.dart';
import 'volume_picker_controller.dart';
import 'widgets/snack_bars.dart';

/// The volume picker, opened by the Download button over the book page.
///
/// It loads the book's table of contents, lets the user tick volumes and
/// adds them to the Downloads tab, which downloads them one at a time.
class VolumePickerSheet extends ConsumerWidget {
  const VolumePickerSheet({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.onViewDownloads,
  });

  final String bookId;

  /// The book's name as the page titles it, shown until the contents
  /// arrive; may be empty.
  final String bookTitle;

  /// Switches to the Downloads tab, from the snackbar's VIEW action.
  final VoidCallback onViewDownloads;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(volumePickerProvider(bookId));
    final merge = ref.watch(settingsProvider).value?.mergeVolumes ?? false;
    final controller = ref.read(volumePickerProvider(bookId).notifier);
    final book = state is PickerReady ? state.book : null;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(bookId: bookId, pageTitle: bookTitle, book: book),
              const SizedBox(height: 16),
              Flexible(
                child: AnimatedSize(
                  duration: motionDuration(context, Motion.standard),
                  curve: Motion.move,
                  alignment: Alignment.topCenter,
                  child: switch (state) {
                    PickerLoading() => const _Loading(),
                    PickerFailed(:final message) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: ErrorView(
                        message: message,
                        onRetry: controller.retry,
                      ),
                    ),
                    PickerReady() => _Volumes(
                      picker: state,
                      onToggle: controller.toggle,
                      onToggleAll: controller.toggleAll,
                    ),
                  },
                ),
              ),
              if (state is PickerReady) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: state.ticked.isEmpty
                      ? null
                      : () => _download(context, controller, merge),
                  child: Text(
                    _downloadLabel(context.l10n, state.ticked.length, merge),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Says exactly what the button does: DOWNLOAD 3 VOLUMES, DOWNLOAD 1
  /// VOLUME, DOWNLOAD 3 AS ONE EPUB with merge on, or a plain DOWNLOAD
  /// while nothing is ticked.
  String _downloadLabel(AppLocalizations l10n, int count, bool merge) {
    if (count > 1 && merge) return l10n.downloadMerged(count);
    return count == 0 ? l10n.download : l10n.downloadVolumes(count);
  }

  /// Adds the ticked volumes to Downloads, closes the sheet and says so in
  /// a snackbar with a way to the Downloads tab.
  void _download(
    BuildContext context,
    VolumePickerController controller,
    bool merge,
  ) {
    final added = controller.download();
    if (added == 0) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      addedSnackBar(
        count: added,
        isMerged: added > 1 && merge,
        onView: onViewDownloads,
      ),
    );
  }
}

/// The book title, then its author and site id in small tracked capitals.
class _Header extends StatelessWidget {
  const _Header({required this.bookId, required this.pageTitle, this.book});

  final String bookId;
  final String pageTitle;

  /// The loaded book, or null while the contents are still on their way.
  final Book? book;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ash = Theme.of(context).colorScheme.onSurfaceVariant;
    final title = book?.title ?? pageTitle;
    final author = book?.author ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.isEmpty ? context.l10n.thisBook : title,
          style: text.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          author.isEmpty
              ? context.l10n.siteId(bookId)
              : context.l10n.authorAndSiteId(author, bookId),
          style: text.labelSmall?.copyWith(color: ash),
        ),
      ],
    );
  }
}

/// The running sodium line and one sentence while the contents load.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ash = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(minHeight: 2),
          const SizedBox(height: 12),
          Text(
            context.l10n.readingContents,
            style: text.bodyMedium?.copyWith(color: ash),
          ),
        ],
      ),
    );
  }
}

/// The SELECT ALL row, when the book has more than one volume, above one
/// checkbox row per volume. The rows scroll when they do not all fit.
class _Volumes extends StatelessWidget {
  const _Volumes({
    required this.picker,
    required this.onToggle,
    required this.onToggleAll,
  });

  final PickerReady picker;
  final void Function(int number) onToggle;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final volumes = picker.book.volumes;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (volumes.length > 1) ...[
          _SelectAllRow(picker: picker, onToggleAll: onToggleAll),
          const Divider(height: 1),
        ],
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: volumes.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final number = volumes[i].number;
              return _VolumeRow(
                volume: volumes[i],
                isTicked: picker.ticked.contains(number),
                isSaved: picker.saved.contains(number),
                isInDownloads: picker.inDownloads.contains(number),
                onToggle: () => onToggle(number),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// SELECT ALL: ticked when every volume that can be is, a dash when some
/// are. Tapping ticks the rest, or unticks all once all are ticked.
class _SelectAllRow extends StatelessWidget {
  const _SelectAllRow({required this.picker, required this.onToggleAll});

  final PickerReady picker;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final canTick = picker.tickable.isNotEmpty;
    return CheckboxListTile(
      tristate: true,
      value: picker.allTicked ? true : (picker.ticked.isEmpty ? false : null),
      onChanged: canTick ? (_) => onToggleAll() : null,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        context.l10n.selectAll,
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );
  }
}

/// A volume's title with its chapter count and mark, ticked by its
/// checkbox. A volume already in Downloads is dimmed and cannot be ticked.
class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.volume,
    required this.isTicked,
    required this.isSaved,
    required this.isInDownloads,
    required this.onToggle,
  });

  final Volume volume;
  final bool isTicked;
  final bool isSaved;
  final bool isInDownloads;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isTicked,
      onChanged: isInDownloads ? null : (_) => onToggle(),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      title: Text(
        volume.title,
        // The explicit style would override the tile's disabled colour, so
        // a volume already in Downloads dims its own title.
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: isInDownloads
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)
              : null,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: _VolumeMeta(
        chapterCount: volume.chapterCount,
        isSaved: isSaved,
        isInDownloads: isInDownloads,
      ),
    );
  }
}

/// "8 CHAPTERS", then "· IN DOWNLOADS", or "· SAVED" with a short cyan
/// line, the line a saved volume carries everywhere in the app.
class _VolumeMeta extends StatelessWidget {
  const _VolumeMeta({
    required this.chapterCount,
    required this.isSaved,
    required this.isInDownloads,
  });

  final int chapterCount;
  final bool isSaved;
  final bool isInDownloads;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ash = Theme.of(context).colorScheme.onSurfaceVariant;
    final l10n = context.l10n;
    final showSaved = isSaved && !isInDownloads;
    final mark = isInDownloads
        ? l10n.markInDownloads
        : (showSaved ? l10n.markSaved : '');
    return Row(
      children: [
        Flexible(
          child: Text(
            '${l10n.chapterCount(chapterCount)}$mark',
            style: text.labelSmall?.copyWith(color: ash),
          ),
        ),
        if (showSaved) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 16,
            child: EmissionLine(
              fraction: 1,
              color: Spectrum.of(context).cyan,
              showTrack: false,
            ),
          ),
        ],
      ],
    );
  }
}
