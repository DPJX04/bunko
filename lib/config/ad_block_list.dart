/// Hosts the web view never loads anything from: ad networks and trackers
/// the site uses. A host also blocks every subdomain, so 'baidu.com' style
/// entries are avoided; only ad and tracking hosts are listed.
///
/// Started 2026-11-01 from the ads seen on the phone (Google ad slots and a
/// full-screen Google vignette) plus the networks Chinese reading sites use.
const blockedHosts = [
  // Google ads and tracking.
  'doubleclick.net',
  'googlesyndication.com',
  'googleadservices.com',
  'adservice.google.com',
  'adtrafficquality.google',
  'fundingchoicesmessages.google.com',
  'googletagmanager.com',
  'googletagservices.com',
  'google-analytics.com',
  'imasdk.googleapis.com',
  // Baidu ads and analytics.
  'pos.baidu.com',
  'cpro.baidu.com',
  'cbjs.baidu.com',
  'hm.baidu.com',
  'dup.baidustatic.com',
  // Tencent, Alibaba and 360 ad networks.
  'gdt.qq.com',
  'pgdt.gtimg.cn',
  'tanx.com',
  'alimama.com',
  'mmstat.com',
  'mediav.com',
  'lianmeng.360.cn',
  'cnzz.com',
  'umeng.com',
  // Common international ad exchanges and pop-up networks.
  'adnxs.com',
  'amazon-adsystem.com',
  'criteo.com',
  'criteo.net',
  'pubmatic.com',
  'rubiconproject.com',
  'openx.net',
  'casalemedia.com',
  'adsrvr.org',
  'taboola.com',
  'outbrain.com',
  'mgid.com',
  'popads.net',
  'popcash.net',
  'exoclick.com',
  'static.cloudflareinsights.com',
];

/// Page elements hidden on every page: ad slots that would otherwise leave
/// empty boxes once their content is blocked.
const hiddenAdSelectors = [
  'ins.adsbygoogle',
  '.adsbygoogle',
  'iframe[id^="google_ads_iframe"]',
  'div[id^="div-gpt-ad"]',
  'iframe[src*="googlesyndication"]',
  'iframe[src*="doubleclick"]',
  // Google's "watch an ad to unlock" Offerwall, seen on the rankings page.
  '.fc-ab-root',
  '.fc-dialog-overlay',
  '.fc-dialog-container',
];
