import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/browse/browse.dart';
import '../features/download/download.dart';
import '../features/library/library.dart';
import '../features/settings/settings.dart';
import '../widgets/fade_through_stack.dart';
import 'app_shell.dart';
import 'bottom_sheet_page.dart';

final _rootNavigator = GlobalKey<NavigatorState>();

/// Every screen in the app: three tabs that keep their state, switching
/// with a fade through, the volume picker sheet over the Browse tab, and
/// Settings and About over the whole app.
///
/// This is the only place features meet: Browse asks for the picker through
/// a callback and never imports the download feature.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigator,
  initialLocation: '/browse',
  routes: [
    StatefulShellRoute(
      builder: (context, state, shell) => AppShell(shell: shell),
      navigatorContainerBuilder: (context, shell, children) {
        return FadeThroughStack(index: shell.currentIndex, children: children);
      },
      branches: [
        StatefulShellBranch(routes: [_browseRoute]),
        StatefulShellBranch(routes: [_downloadsRoute]),
        StatefulShellBranch(routes: [_libraryRoute]),
      ],
    ),
  ],
);

/// The Browse tab, with the volume picker as a sheet on top of it.
final GoRoute _browseRoute = GoRoute(
  path: '/browse',
  builder: (context, state) => BrowseScreen(
    onDownloadBook: (bookId, bookTitle) => context.push(
      Uri(
        path: '/browse/books/$bookId/volumes',
        queryParameters: {'title': bookTitle},
      ).toString(),
    ),
  ),
  routes: [
    GoRoute(
      path: 'books/:bookId/volumes',
      parentNavigatorKey: _rootNavigator,
      pageBuilder: (context, state) => BottomSheetPage(
        key: state.pageKey,
        child: VolumePickerSheet(
          bookId: state.pathParameters['bookId']!,
          bookTitle: state.uri.queryParameters['title'] ?? '',
          onViewDownloads: () => appRouter.go('/downloads'),
        ),
      ),
    ),
  ],
);

final _downloadsRoute = GoRoute(
  path: '/downloads',
  builder: (context, state) =>
      DownloadsScreen(onBrowse: () => _goToBrowse(context)),
);

/// The Library tab, with Settings and About as full screens over the app.
final _libraryRoute = GoRoute(
  path: '/library',
  builder: (context, state) => LibraryScreen(
    onBrowse: () => _goToBrowse(context),
    onSettings: () => context.push('/library/settings'),
  ),
  routes: [
    GoRoute(
      path: 'settings',
      parentNavigatorKey: _rootNavigator,
      builder: (context, state) => SettingsScreen(
        onAbout: () => context.push('/library/settings/about'),
      ),
      routes: [
        GoRoute(
          path: 'about',
          parentNavigatorKey: _rootNavigator,
          builder: (context, state) => const AboutScreen(),
        ),
      ],
    ),
  ],
);

/// Switches to the Browse tab from inside another tab.
void _goToBrowse(BuildContext context) {
  StatefulNavigationShell.of(context).goBranch(0);
}
