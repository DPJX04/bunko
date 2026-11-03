import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/download_record.dart';
import '../../../widgets/emission_line.dart';
import '../../../widgets/emission_tick_border.dart';
import '../../../widgets/motion.dart';
import '../../../widgets/spectrum.dart';
import '../library_controller.dart';
import '../volume_label.dart';

/// One book on the Library tab: a header with its title and volume count
/// that folds and opens the book, then, while open, one row per saved
/// volume, split by hairlines. The book's own line colour, from its colour
/// slot, marks its header tick and its rows, so books tell apart at a
/// glance.
///
/// Give each section its book's id as key, so a book keeps its open or
/// folded state when the list reorders.
class LibraryBookSection extends StatefulWidget {
  const LibraryBookSection({
    super.key,
    required this.book,
    required this.onOpen,
    this.initiallyOpen = true,
  });

  final LibraryBook book;
  final void Function(DownloadRecord volume) onOpen;

  /// Whether the book shows its volumes before the owner taps its header.
  final bool initiallyOpen;

  @override
  State<LibraryBookSection> createState() => _LibraryBookSectionState();
}

class _LibraryBookSectionState extends State<LibraryBookSection> {
  late var _isOpen = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    final color = Spectrum.of(context).book(widget.book.colorSlot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BookHeader(
          book: widget.book,
          color: color,
          isOpen: _isOpen,
          onToggle: () => setState(() => _isOpen = !_isOpen),
        ),
        // The rows slide out from under the header and back.
        AnimatedSize(
          duration: motionDuration(context, Motion.standard),
          curve: Motion.move,
          alignment: Alignment.topCenter,
          child: _isOpen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final volume in widget.book.volumes) ...[
                      const Divider(height: 1),
                      _VolumeRow(
                        volume: volume,
                        bookTitle: widget.book.title,
                        color: color,
                        onOpen: () => widget.onOpen(volume),
                      ),
                    ],
                  ],
                )
              : const SizedBox(width: double.infinity),
        ),
        const Divider(height: 1),
      ],
    );
  }
}

/// The book's header: the tick in the book's colour on its leading edge,
/// the book title set heavier than the volume rows, the volume count, and
/// a chevron that turns as the book opens. The whole header is the target.
class _BookHeader extends StatelessWidget {
  const _BookHeader({
    required this.book,
    required this.color,
    required this.isOpen,
    required this.onToggle,
  });

  final LibraryBook book;

  /// The book's line colour.
  final Color color;
  final bool isOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final ash = Theme.of(context).colorScheme.onSurfaceVariant;
    final duration = motionDuration(context, Motion.standard);
    return Semantics(
      button: true,
      expanded: isOpen,
      hint: isOpen ? l10n.hideVolumes : l10n.showVolumes,
      child: InkWell(
        onTap: onToggle,
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: EmissionTickBorder(tickColor: color, side: BorderSide.none),
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontVariations: const [
                            FontVariation.width(100),
                            FontVariation.weight(600),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.volumeCount(book.volumes.length),
                        style: text.labelSmall?.copyWith(color: ash),
                      ),
                    ],
                  ),
                ),
                // The same 48 dp slot as the rows' open mark, so the
                // chevron lines up above them.
                SizedBox(
                  width: 48,
                  height: 48,
                  child: AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: duration,
                    curve: Motion.move,
                    child: Icon(Icons.expand_more_rounded, color: ash),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A saved volume: its title without the book title the header already
/// shows, when it was saved with the short saved line in the book's
/// colour, and an open mark. The whole row opens it.
class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.volume,
    required this.bookTitle,
    required this.color,
    required this.onOpen,
  });

  final DownloadRecord volume;
  final String bookTitle;

  /// The book's line colour.
  final Color color;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final ash = Theme.of(context).colorScheme.onSurfaceVariant;
    return Semantics(
      button: true,
      hint: l10n.opensInReader,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(24, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      volumeLabel(l10n, bookTitle, volume.volumeTitle),
                      style: text.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          l10n.savedOn(dayMonthOf(l10n, volume.downloadedAt)),
                          style: text.labelSmall?.copyWith(color: ash),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 16,
                          child: EmissionLine(
                            fraction: 1,
                            color: color,
                            showTrack: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Lines up with the 48 dp targets elsewhere; the row is the
              // button, so the mark only says where it leads.
              SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.open_in_new_rounded, color: ash, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
