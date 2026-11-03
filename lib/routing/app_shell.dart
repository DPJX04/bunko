import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/browse/browse.dart';
import '../features/download/download.dart';
import '../l10n/l10n.dart';
import '../widgets/count_badge.dart';
import '../widgets/emission_rail.dart';
import '../widgets/spectrum.dart';

/// The app frame: the open tab above the navigation bar, with the emission
/// rail marking which tab is open and a count of the volumes still in the
/// queue on the Downloads tab.
///
/// Back on Downloads or Library returns to Browse first, as Material asks.
/// Back on Browse goes back through the site, and leaves the app only once
/// the site has no page to go back to. The frame must know that last part:
/// on Android 16 the system closes the app without asking Flutter whenever
/// the frame says it cannot handle Back.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final spectrum = Spectrum.of(context);
    final browseCanGoBack = ref.watch(browseCanGoBackProvider);
    final queued = ref.watch(activeDownloadCountProvider);
    return PopScope(
      canPop: shell.currentIndex == 0 && !browseCanGoBack,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) shell.goBranch(0);
      },
      child: SavedSnackListener(
        child: Scaffold(
          body: shell,
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColoredBox(
                color: colors.surfaceContainerLowest,
                child: EmissionRail(
                  selectedIndex: shell.currentIndex,
                  colors: [spectrum.violet, spectrum.green, spectrum.cyan],
                  railColor: colors.outlineVariant,
                  glow: spectrum.glow,
                ),
              ),
              NavigationBar(
                selectedIndex: shell.currentIndex,
                onDestinationSelected: shell.goBranch,
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.explore_outlined),
                    selectedIcon: const Icon(Icons.explore),
                    label: context.l10n.tabBrowse,
                  ),
                  NavigationDestination(
                    icon: CountBadge(
                      count: queued,
                      child: const Icon(Icons.download_outlined),
                    ),
                    selectedIcon: CountBadge(
                      count: queued,
                      child: const Icon(Icons.download),
                    ),
                    label: context.l10n.tabDownloads,
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.local_library_outlined),
                    selectedIcon: const Icon(Icons.local_library),
                    label: context.l10n.tabLibrary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
