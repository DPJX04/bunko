import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../widgets/emission_line.dart';
import '../../../widgets/emission_tick_border.dart';
import '../../../widgets/motion.dart';
import '../../../widgets/spectrum.dart';
import '../download_task.dart';

/// One row on the Downloads tab: the volume and book, a percentage or
/// status word, and one line whose colour tells the state. Sodium grows
/// while downloading, cyan fills once saved, red fills on failure.
/// Waiting and downloading rows end in a close button that cancels them;
/// a saved row offers OPEN.
class DownloadTaskTile extends StatelessWidget {
  const DownloadTaskTile({
    super.key,
    required this.task,
    required this.onRetry,
    required this.onCancel,
    required this.onOpen,
  });

  final DownloadTask task;
  final VoidCallback onRetry;
  final VoidCallback onCancel;
  final VoidCallback onOpen;

  /// The close button's 48 dp target reaches 12 dp past the row's 24 dp
  /// gutter, so its icon lines up with the end of the line below.
  static const _gutter = 24.0;
  static const _buttonOverhang = 12.0;

  @override
  Widget build(BuildContext context) {
    final duration = motionDuration(context, Motion.standard);
    const lineInset = EdgeInsetsDirectional.only(end: _buttonOverhang);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        _gutter,
        12,
        _gutter - _buttonOverhang,
        16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Row(
              children: [
                Expanded(child: _Heading(task: task)),
                AnimatedSize(
                  duration: duration,
                  curve: Motion.move,
                  child: task.isActive
                      ? IconButton(
                          tooltip: context.l10n.cancelDownloadTooltip,
                          icon: const Icon(Icons.close_rounded),
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          onPressed: onCancel,
                        )
                      : const SizedBox(width: _buttonOverhang),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: lineInset,
            child: EmissionLine(
              fraction: _lineLength(task),
              color: _lineColor(context, task.status),
            ),
          ),
          Padding(
            padding: lineInset,
            child: AnimatedSize(
              duration: duration,
              curve: Motion.move,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: duration,
                // Keeps the detail on the leading edge; the default centres it.
                layoutBuilder: (current, previous) => Stack(
                  alignment: AlignmentDirectional.topStart,
                  children: [...previous, ?current],
                ),
                child: _Detail(
                  key: ValueKey(task.status),
                  task: task,
                  onRetry: onRetry,
                  onOpen: onOpen,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// How much of the line is lit: the percentage while downloading, all of
  /// it once saved or failed, none while waiting.
  double _lineLength(DownloadTask task) {
    return switch (task.status) {
      DownloadStatus.waiting => 0,
      DownloadStatus.downloading => task.percent / 100,
      DownloadStatus.done || DownloadStatus.failed => 1,
    };
  }

  /// The line's wavelength: sodium for downloading now, cyan for saved, red
  /// for failed.
  Color _lineColor(BuildContext context, DownloadStatus status) {
    final spectrum = Spectrum.of(context);
    return switch (status) {
      DownloadStatus.waiting || DownloadStatus.downloading => spectrum.sodium,
      DownloadStatus.done => spectrum.cyan,
      DownloadStatus.failed => spectrum.red,
    };
  }
}

/// The volume title over the book title, with the status at the trailing
/// end of the first line.
class _Heading extends StatelessWidget {
  const _Heading({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ash = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: text.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                task.bookTitle,
                style: text.bodyMedium?.copyWith(color: ash),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        AnimatedSwitcher(
          duration: motionDuration(context, Motion.standard),
          child: _StatusLabel(key: ValueKey(task.status), task: task),
        ),
      ],
    );
  }
}

/// The percentage while downloading, otherwise one tracked status word.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({super.key, required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelLarge;
    final l10n = context.l10n;
    final label = switch (task.status) {
      DownloadStatus.waiting => l10n.statusWaiting,
      DownloadStatus.downloading => '${task.percent}%',
      DownloadStatus.done => l10n.statusSaved,
      DownloadStatus.failed => l10n.statusFailed,
    };
    final isQuiet = task.status == DownloadStatus.waiting;
    return Text(
      label,
      style: style?.copyWith(
        color: isQuiet ? colors.onSurfaceVariant : colors.onSurface,
        // Same-width digits, so the percentage does not jitter as it climbs.
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// What sits under the line: where a saved volume went with an OPEN
/// button, or why a volume failed with a RETRY button. Nothing while
/// waiting or downloading.
class _Detail extends StatelessWidget {
  const _Detail({
    super.key,
    required this.task,
    required this.onRetry,
    required this.onOpen,
  });

  final DownloadTask task;
  final VoidCallback onRetry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ash = Theme.of(context).colorScheme.onSurfaceVariant;
    switch (task.status) {
      case DownloadStatus.waiting:
      case DownloadStatus.downloading:
        return const SizedBox(width: double.infinity);
      case DownloadStatus.done:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.savedToFolder,
                style: text.bodyMedium?.copyWith(color: ash),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                // The cyan tick of saved volumes: it acts on the saved file.
                child: OutlinedButton(
                  onPressed: onOpen,
                  style: ButtonStyle(
                    shape: tickShape(
                      tick: Spectrum.of(context).cyan,
                      outline: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  child: Text(context.l10n.open),
                ),
              ),
            ],
          ),
        );
      case DownloadStatus.failed:
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The red line marks the failure; the reason stays in the
              // legend colour, since text never takes a spectral colour.
              Text(
                localizedError(context.l10n, task.errorMessage ?? ''),
                style: text.bodyMedium,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.retry),
                ),
              ),
            ],
          ),
        );
    }
  }
}
