import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../config/ad_block_list.dart';

// The web view plugin's own contentBlockers are not used: with any rule
// set, its Android side sends a HEAD request for every file a page loads,
// and waits for the answer before loading the file, only to learn its
// type. That made every page, and Back and Home, slow. Instead the web
// view asks [blockedResponse] about each request, which only looks at
// the host, and [hideAdsScript] hides the ad slots with one stylesheet.

/// The blocked hosts as a set, for a quick look-up of each request.
final _blocked = blockedHosts.toSet();

/// Whether [host] is a blocked host or one of its subdomains, such as
/// 'pagead2.googlesyndication.com'. A host that only contains a blocked
/// name, such as 'notdoubleclick.net', is not blocked.
bool isBlockedHost(String host) {
  var rest = host.toLowerCase();
  while (true) {
    if (_blocked.contains(rest)) return true;
    final dot = rest.indexOf('.');
    if (dot < 0) return false;
    rest = rest.substring(dot + 1);
  }
}

/// An empty answer for a request to a blocked host, so the ad never
/// loads, or null to let the request through.
WebResourceResponse? blockedResponse(WebResourceRequest request) {
  if (!isBlockedHost(request.url.host)) return null;
  return WebResourceResponse(contentType: 'text/plain', data: Uint8List(0));
}

/// A script that adds one stylesheet hiding the ad slots as each page
/// starts, so their empty boxes never show. The stylesheet also hides
/// slots the site adds later.
UserScript hideAdsScript() {
  final css = '${hiddenAdSelectors.join(',')}{display:none!important}';
  return UserScript(
    source:
        '(function(){var s=document.createElement("style");'
        's.textContent=${jsonEncode(css)};'
        '(document.head||document.documentElement).appendChild(s);})();',
    injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  );
}
