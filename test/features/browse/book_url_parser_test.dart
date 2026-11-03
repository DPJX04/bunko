import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/features/browse/book_url_parser.dart';

void main() {
  test('a book main page gives its id', () {
    expect(
      bookIdOfBookPage('https://www.bilinovel.net/novel/5330.html'),
      '5330',
    );
  });

  test('a catalog page gives its id, with or without a trailing slash', () {
    expect(
      bookIdOfBookPage('https://www.bilinovel.net/novel/5330/catalog'),
      '5330',
    );
    expect(
      bookIdOfBookPage('https://www.bilinovel.net/novel/5330/catalog/'),
      '5330',
    );
  });

  test('a volume page gives its id', () {
    expect(
      bookIdOfBookPage('https://www.bilinovel.net/novel/5330/vol_12345.html'),
      '5330',
    );
  });

  test('a chapter page gives null so the button stays out of the text', () {
    expect(
      bookIdOfBookPage('https://www.bilinovel.net/novel/5330/263719.html'),
      isNull,
    );
    expect(
      bookIdOfBookPage('https://www.bilinovel.net/novel/5330/263719_2.html'),
      isNull,
    );
  });

  test('every site host works, with any subdomain', () {
    expect(bookIdOfBookPage('https://www.linovelib.com/novel/7.html'), '7');
    expect(bookIdOfBookPage('https://w.linovelib.com/novel/7.html'), '7');
    expect(bookIdOfBookPage('https://www.bilinovel.com/novel/7.html'), '7');
    expect(bookIdOfBookPage('http://bilinovel.net/novel/7.html'), '7');
  });

  test('query strings and fragments do not matter', () {
    expect(
      bookIdOfBookPage(
        'https://www.bilinovel.net/novel/5330.html?from=top#info',
      ),
      '5330',
    );
  });

  test('other site pages give null', () {
    for (final path in [
      '/',
      '/top.html',
      '/topfull/weekvote/1.html',
      '/wenku/',
      '/wiki/12.html',
      '/bookcase.php',
    ]) {
      expect(
        bookIdOfBookPage('https://www.bilinovel.net$path'),
        isNull,
        reason: path,
      );
    }
  });

  test('other sites and broken URLs give null', () {
    expect(
      bookIdOfBookPage('https://evil-bilinovel.net.example.com/novel/1.html'),
      isNull,
    );
    expect(bookIdOfBookPage('https://notlinovelib.com/novel/1.html'), isNull);
    expect(bookIdOfBookPage('about:blank'), isNull);
    expect(bookIdOfBookPage('::not a url::'), isNull);
  });
}
