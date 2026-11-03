/// Shortens a site page title to the part before its first underscore,
/// such as '酒醉就旅行的今里小姐_结城弘作品_GA文库_哔哩轻小说' giving
/// '酒醉就旅行的今里小姐'. The site appends author, imprint and site name
/// after underscores, which the toolbar has no room for.
String shortPageTitle(String title) {
  final cut = title.indexOf('_');
  final short = cut > 0 ? title.substring(0, cut) : title;
  return short.trim();
}
