import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/features/browse/browse_controller.dart';

void main() {
  late ProviderContainer container;
  late BrowseController controller;

  BrowseState state() => container.read(browseControllerProvider);

  setUp(() {
    container = ProviderContainer();
    controller = container.read(browseControllerProvider.notifier);
  });
  tearDown(() => container.dispose());

  test('a book page shows the Download button', () {
    controller.pageStarted('https://www.bilinovel.net/novel/5330.html');
    expect(state().bookId, '5330');
    expect(state().isLoading, isTrue);
  });

  test('moving on to a chapter page hides it again', () {
    controller.pageStarted('https://www.bilinovel.net/novel/5330.html');
    controller.historyChanged(
      'https://www.bilinovel.net/novel/5330/263719.html',
      canGoBack: true,
    );
    expect(state().bookId, isNull);
  });

  test('Back is ready as soon as a navigation commits, before it loads', () {
    controller.pageStarted('https://www.bilinovel.net/top.html');
    controller.historyChanged(
      'https://www.bilinovel.net/top.html',
      canGoBack: true,
    );
    expect(state().isLoading, isTrue);
    expect(state().canGoBack, isTrue);
  });

  test('finishing a page records its progress', () {
    controller.pageStarted('https://www.bilinovel.net/');
    controller.progressChanged(40);
    expect(state().progress, 0.4);
    controller.pageFinished('https://www.bilinovel.net/');
    expect(state().isLoading, isFalse);
    expect(state().progress, 1);
  });

  test('the title follows the page', () {
    controller.titleChanged('轻小说文库排行榜_哔哩轻小说');
    expect(state().title, '轻小说文库排行榜_哔哩轻小说');
  });

  test('scrolling down folds the button and scrolling up opens it', () {
    controller.scrolledTo(200);
    expect(state().isFabExpanded, isFalse);
    controller.scrolledTo(150);
    expect(state().isFabExpanded, isTrue);
  });

  test('tiny scroll jitter changes nothing', () {
    controller.scrolledTo(5);
    expect(state().isFabExpanded, isTrue);
  });

  test('a failed load keeps its message until the next page starts', () {
    controller.loadFailed('No internet connection. Check Wi-Fi and tap Retry.');
    expect(state().loadError, isNotNull);
    expect(state().isLoading, isFalse);
    controller.pageStarted('https://www.bilinovel.net/');
    expect(state().loadError, isNull);
  });

  test('a book page gives its short title for the picker', () {
    controller.pageStarted('https://www.bilinovel.net/novel/5330.html');
    controller.titleChanged('酒醉就旅行的今里小姐_结城弘作品_GA文库_哔哩轻小说');
    expect(state().bookTitle, '酒醉就旅行的今里小姐');
  });

  test('a book page that failed to load gives no title for the picker', () {
    controller.pageStarted('https://www.bilinovel.net/novel/5330.html');
    controller.titleChanged('Web page not available');
    controller.loadFailed('No internet connection. Check Wi-Fi and tap Retry.');
    expect(state().bookTitle, isEmpty);
  });
}
