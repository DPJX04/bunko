import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_config.dart';
import '../../repositories/novel_repository.dart';
import '../../utils/error_messages.dart';
import '../../widgets/error_view.dart';
import '../../widgets/motion.dart';
import 'ad_blockers.dart';
import 'browse_controller.dart';
import 'widgets/browse_toolbar.dart';
import 'widgets/download_fab.dart';

/// The Browse tab: the site in a web view with ads blocked, under a
/// toolbar with Back, the page title and Home. The phone's Back goes back
/// through the site first; the Download button shows on book pages.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key, required this.onDownloadBook});

  /// Opens the volume picker for a book id. Routing supplies it, so this
  /// feature never imports the download feature.
  /// Gets the book id and its short title, such as ('5330', '酒醉就旅行的今里小姐').
  final void Function(String bookId, String bookTitle) onDownloadBook;

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  InAppWebViewController? _web;

  BrowseController get _controller {
    return ref.read(browseControllerProvider.notifier);
  }

  /// Web view settings: the site sees upstream's User-Agent, each request
  /// is checked against the ad hosts (see ad_blockers.dart), and debug
  /// builds can be inspected from a computer.
  late final _settings = InAppWebViewSettings(
    userAgent: ref.read(novelRepositoryProvider).browserUserAgent,
    useShouldInterceptRequest: true,
    isInspectable: kDebugMode,
    supportMultipleWindows: false,
    javaScriptCanOpenWindowsAutomatically: false,
    mediaPlaybackRequiresUserGesture: true,
  );

  /// Updates Back's state; a navigation commits long before the page ends.
  Future<void> _onHistory(InAppWebViewController web, WebUri? url) async {
    if (url == null) return;
    _controller.historyChanged(
      url.toString(),
      canGoBack: await web.canGoBack(),
    );
  }

  /// Shows a readable error when the page itself, not one of its parts,
  /// fails to load.
  void _onError(WebResourceRequest request, WebResourceError error) {
    if (request.isForMainFrame == false) return;
    _controller.loadFailed(messageForPageError(error.type));
  }

  void _goBack() => _web?.goBack();

  void _goHome() {
    _web?.loadUrl(urlRequest: URLRequest(url: WebUri(AppConfig.siteHomeUrl)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(browseControllerProvider);
    final colors = Theme.of(context).colorScheme;
    final isDark = colors.brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: PopScope(
        canPop: !state.canGoBack,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _goBack();
        },
        child: Scaffold(
          backgroundColor: colors.surfaceContainerLowest,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                BrowseToolbar(
                  title: state.title,
                  canGoBack: state.canGoBack,
                  progress: state.progress,
                  isLoading: state.isLoading,
                  onBack: _goBack,
                  onHome: _goHome,
                ),
                Expanded(child: Stack(children: [_webView(), _errorCover()])),
              ],
            ),
          ),
          floatingActionButton: state.bookId == null
              ? null
              : DownloadFab(
                  isExpanded: state.isFabExpanded,
                  onPressed: () =>
                      widget.onDownloadBook(state.bookId!, state.bookTitle),
                ),
        ),
      ),
    );
  }

  /// The web view, passing each of its events on to the controller.
  Widget _webView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(AppConfig.siteHomeUrl)),
      initialSettings: _settings,
      initialUserScripts: UnmodifiableListView([hideAdsScript()]),
      shouldInterceptRequest: (_, request) async => blockedResponse(request),
      onWebViewCreated: (web) => _web = web,
      onLoadStart: (_, url) => _controller.pageStarted(url.toString()),
      onProgressChanged: (_, percent) => _controller.progressChanged(percent),
      onLoadStop: (_, url) => _controller.pageFinished(url.toString()),
      onUpdateVisitedHistory: (web, url, _) => _onHistory(web, url),
      onTitleChanged: (_, title) => _controller.titleChanged(title),
      onReceivedError: (_, request, error) => _onError(request, error),
      onScrollChanged: (_, _, y) => _controller.scrolledTo(y.toDouble()),
    );
  }

  /// Covers the web view with a plain error and Retry when a page fails,
  /// fading in and out instead of popping.
  Widget _errorCover() {
    final message = ref.watch(browseControllerProvider).loadError;
    return AnimatedSwitcher(
      duration: motionDuration(context, Motion.standard),
      switchInCurve: Motion.enter,
      switchOutCurve: Motion.exit,
      child: message == null
          ? const SizedBox.shrink()
          : ColoredBox(
              key: ValueKey(message),
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ErrorView(
                    message: message,
                    onRetry: () => _web?.reload(),
                  ),
                ),
              ),
            ),
    );
  }
}
