import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../widgets/motion.dart';
import '../page_title.dart';
import 'page_load_line.dart';

/// The strip above the site: Back, the page's short title and Home, with
/// the page-load line running along its bottom edge.
class BrowseToolbar extends StatelessWidget {
  const BrowseToolbar({
    super.key,
    required this.title,
    required this.canGoBack,
    required this.progress,
    required this.isLoading,
    required this.onBack,
    required this.onHome,
  });

  final String title;
  final bool canGoBack;
  final double progress;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onHome;

  /// Toolbar height, enough for 48 dp touch targets.
  static const height = 48.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ColoredBox(
      color: colors.surfaceContainerLowest,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Row(
              children: [
                _BackButton(enabled: canGoBack, onPressed: onBack),
                Expanded(child: _Title(title: shortPageTitle(title))),
                IconButton(
                  tooltip: context.l10n.browseHome,
                  icon: const Icon(Icons.home_outlined),
                  onPressed: onHome,
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Divider(height: 0, color: colors.outlineVariant),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PageLoadLine(progress: progress, isLoading: isLoading),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back, fading to a dim mark when the site has no page to go back to.
class _BackButton extends StatelessWidget {
  const _BackButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.32,
      duration: motionDuration(context, Motion.quick),
      child: IconButton(
        tooltip: context.l10n.browseBack,
        icon: const Icon(Icons.arrow_back_rounded),
        style: IconButton.styleFrom(disabledForegroundColor: color),
        onPressed: enabled ? onPressed : null,
      ),
    );
  }
}

/// The page title, cross-fading when the page changes.
class _Title extends StatelessWidget {
  const _Title({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: motionDuration(context, Motion.standard),
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [...previous, ?current],
      ),
      child: Text(
        title,
        key: ValueKey(title),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}
