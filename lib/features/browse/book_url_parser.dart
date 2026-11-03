/// Reads the book id from a book page URL, such as
/// 'https://www.bilinovel.net/novel/5330.html' giving '5330'.
///
/// Book pages are a book's main page, its catalog and its volume pages.
/// Chapter pages give null, so the download button never covers the text
/// being read. Hosts follow bili_novel_packer's own pattern: linovelib.com,
/// bilinovel.com and bilinovel.net, with any subdomain.
String? bookIdOfBookPage(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || !_siteHost.hasMatch(uri.host)) return null;
  for (final pattern in _bookPagePaths) {
    final match = pattern.firstMatch(uri.path);
    if (match != null) return match.group(1);
  }
  return null;
}

/// Hosts of the site, with or without a subdomain such as www or m.
final _siteHost = RegExp(r'(^|\.)(linovelib\.com|bilinovel\.(com|net))$');

/// Book page paths, as found on the mobile site on 2026-11-01.
final _bookPagePaths = [
  RegExp(r'^/novel/(\d+)\.html$'),
  RegExp(r'^/novel/(\d+)/catalog/?$'),
  RegExp(r'^/novel/(\d+)/vol_\d+\.html$'),
];
