import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'book_url_parser.dart';
import 'page_title.dart';

/// What the Browse tab shows: the page, its title, how far it has loaded,
/// whether it is a book page, and whether the Download button is folded.
class BrowseState {
  const BrowseState({
    this.url = '',
    this.title = '',
    this.progress = 0,
    this.isLoading = true,
    this.bookId,
    this.canGoBack = false,
    this.isFabExpanded = true,
    this.loadError,
  });

  final String url;

  /// The page's own title, shown in the toolbar.
  final String title;

  /// Page load progress, from 0 to 1.
  final double progress;
  final bool isLoading;

  /// The book this page belongs to, or null when it is not a book page.
  final String? bookId;

  /// True when the web view has a page to go back to.
  final bool canGoBack;

  /// False while the reader scrolls down, so the button folds to its icon.
  final bool isFabExpanded;

  /// One sentence about a failed page load, or null.
  final String? loadError;

  /// The book's short title for the volume picker, such as
  /// '酒醉就旅行的今里小姐'. Empty when the page failed to load, since the
  /// title is then the web view's own error page title.
  String get bookTitle => loadError == null ? shortPageTitle(title) : '';

  /// Returns a copy with the given fields replaced. [bookId] and
  /// [loadError] are always replaced, because null is a real value for them.
  BrowseState copyWith({
    String? url,
    String? title,
    double? progress,
    bool? isLoading,
    required String? bookId,
    bool? canGoBack,
    bool? isFabExpanded,
    required String? loadError,
  }) {
    return BrowseState(
      url: url ?? this.url,
      title: title ?? this.title,
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      bookId: bookId,
      canGoBack: canGoBack ?? this.canGoBack,
      isFabExpanded: isFabExpanded ?? this.isFabExpanded,
      loadError: loadError,
    );
  }
}

/// Gives the Browse tab its state.
final browseControllerProvider =
    NotifierProvider<BrowseController, BrowseState>(BrowseController.new);

/// True while the Browse page has a page to go back to. The app frame
/// watches it: Android 16 closes the app on Back unless the frame says it
/// can handle Back, and only this feature knows the page's history.
final browseCanGoBackProvider = Provider<bool>((ref) {
  return ref.watch(browseControllerProvider.select((state) => state.canGoBack));
});

/// Turns web view events into [BrowseState]. It never holds the web view
/// itself, so it can be tested without one.
class BrowseController extends Notifier<BrowseState> {
  /// Scroll distance, in pixels, that counts as a real scroll.
  static const _scrollSlop = 12.0;

  double _lastScrollY = 0;

  @override
  BrowseState build() => const BrowseState();

  /// A page started loading: reset progress and the button, read its id.
  void pageStarted(String url) {
    _lastScrollY = 0;
    state = state.copyWith(
      url: url,
      progress: 0,
      isLoading: true,
      bookId: bookIdOfBookPage(url),
      isFabExpanded: true,
      loadError: null,
    );
  }

  /// Load progress changed, as a percentage from 0 to 100.
  void progressChanged(int percent) {
    state = state.copyWith(
      progress: percent / 100,
      bookId: state.bookId,
      loadError: state.loadError,
    );
  }

  /// A page finished loading.
  void pageFinished(String url) {
    state = state.copyWith(
      url: url,
      progress: 1,
      isLoading: false,
      bookId: bookIdOfBookPage(url),
      loadError: state.loadError,
    );
  }

  /// The history changed, which happens as soon as a navigation commits,
  /// long before a slow page finishes. Back relies on this being early.
  void historyChanged(String url, {required bool canGoBack}) {
    state = state.copyWith(
      url: url,
      canGoBack: canGoBack,
      bookId: bookIdOfBookPage(url),
      loadError: state.loadError,
    );
  }

  /// The page's title changed.
  void titleChanged(String? title) {
    state = state.copyWith(
      title: title ?? '',
      bookId: state.bookId,
      loadError: state.loadError,
    );
  }

  /// The page failed to load; [message] is one readable sentence.
  void loadFailed(String message) {
    state = state.copyWith(
      isLoading: false,
      bookId: state.bookId,
      loadError: message,
    );
  }

  /// The page scrolled to [y]: fold the button going down, open it going up.
  void scrolledTo(double y) {
    final delta = y - _lastScrollY;
    if (delta.abs() < _scrollSlop) return;
    _lastScrollY = y;
    final expanded = delta < 0 || y < _scrollSlop;
    if (expanded == state.isFabExpanded) return;
    state = state.copyWith(
      isFabExpanded: expanded,
      bookId: state.bookId,
      loadError: state.loadError,
    );
  }
}
