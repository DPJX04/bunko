import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import '../../models/download_record.dart';
import '../../models/result.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/spectrum.dart';
import '../../widgets/spectrum_plate.dart';
import 'library_controller.dart';
import 'widgets/library_book_section.dart';

/// The Library tab: every saved volume, grouped by book, the book saved
/// most recently first. That book starts open and the others folded; a
/// tap on a book's header opens or folds it. Tapping a volume opens it in
/// a reader app. With nothing saved it shows its empty state.
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({
    super.key,
    required this.onBrowse,
    required this.onSettings,
  });

  /// Switches to the Browse tab.
  final VoidCallback onBrowse;

  /// Opens the Settings screen.
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(libraryProvider);
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabLibrary),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: onSettings,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: books.isEmpty
          ? _Empty(onBrowse: onBrowse)
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                for (final (index, book) in books.indexed)
                  LibraryBookSection(
                    key: ValueKey(book.bookId),
                    book: book,
                    initiallyOpen: index == 0,
                    onOpen: (volume) => _open(context, ref, volume),
                  ),
              ],
            ),
    );
  }

  /// Opens [volume] in a reader app, or says why it cannot.
  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    DownloadRecord volume,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final opened = await ref.read(libraryProvider.notifier).open(volume);
    if (opened is Err<void>) {
      messenger.showSnackBar(
        SnackBar(content: Text(localizedError(l10n, opened.message))),
      );
    }
  }
}

/// The empty state: a plate of half-height cyan lines and the way to
/// Browse.
class _Empty extends StatelessWidget {
  const _Empty({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final spectrum = Spectrum.of(context);
    final saved = spectrum.cyan.withValues(alpha: 0.7);
    final l10n = context.l10n;
    return EmptyState(
      art: SpectrumPlate(
        lines: [
          PlateLine(0.44, saved, LineForm.half),
          PlateLine(0.58, saved, LineForm.half),
          PlateLine(0.86, saved, LineForm.half),
        ],
      ),
      title: l10n.libraryEmptyTitle,
      message: l10n.libraryEmptyMessage,
      actionLabel: l10n.browseBooks,
      actionTick: spectrum.violet,
      onAction: onBrowse,
    );
  }
}
