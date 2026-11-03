import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/config/ad_block_list.dart';
import 'package:light_novel_downloader/features/browse/ad_blockers.dart';

/// Whether a request for [url] is blocked.
bool blocks(String url) => isBlockedHost(Uri.parse(url).host);

void main() {
  test('blocks every ad URL seen on the phone, whole URL matched', () {
    expect(
      blocks('https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js'),
      isTrue,
    );
    expect(
      blocks('https://googleads.g.doubleclick.net/pagead/ads?x=1'),
      isTrue,
    );
    expect(
      blocks('https://fundingchoicesmessages.google.com/i/ca-pub-1?href=x'),
      isTrue,
    );
    expect(blocks('https://ep1.adtrafficquality.google/getconfig'), isTrue);
    expect(blocks('https://hm.baidu.com/hm.js?abc'), isTrue);
  });

  test('blocks a bare host with no path', () {
    expect(blocks('https://doubleclick.net'), isTrue);
  });

  test('never blocks the site, its fonts or its images', () {
    expect(blocks('https://www.bilinovel.net/novel/5330.html'), isFalse);
    expect(blocks('https://www.linovelib.com/top.html'), isFalse);
    expect(blocks('https://fonts.googleapis.com/css?family=x'), isFalse);
    expect(blocks('https://img3.readpai.com/1/1234.jpg'), isFalse);
  });

  test('does not match a host that only contains a blocked name', () {
    expect(blocks('https://notdoubleclick.net.example.com/'), isFalse);
    expect(blocks('https://example.com/?ref=doubleclick.net'), isFalse);
    expect(blocks('https://www.baidu.com/s?wd=x'), isFalse);
  });

  test('hides every ad slot with one stylesheet as the page starts', () {
    final script = hideAdsScript();

    expect(script.injectionTime, UserScriptInjectionTime.AT_DOCUMENT_START);
    for (final selector in hiddenAdSelectors) {
      expect(script.source, contains(selector.replaceAll('"', r'\"')));
    }
    expect(script.source, contains('display:none!important'));
  });
}
