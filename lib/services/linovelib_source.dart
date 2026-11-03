import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:bili_novel_packer/logger.dart' as upstream_log;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

/// The one linovelib source for the whole app. Upstream's rate limits count
/// per source, so a second source would double the request rate.
final linovelibSourceProvider = Provider<BiliNovelSource>(
  (ref) => createLinovelibSource(),
);

/// Creates bili_novel_packer's linovelib source, set up to run on a phone.
///
/// Upstream's logger writes to 'bili_novel.log' in the working folder,
/// which is read only on Android. Its `logger` is a plain top level
/// variable, so swapping it before the source is built means upstream never
/// opens that file. Warnings only, because upstream logs whole HTML pages
/// at info level.
BiliNovelSource createLinovelibSource() {
  upstream_log.logger = Logger(
    printer: SimplePrinter(colors: false),
    output: ConsoleOutput(),
    level: Level.warning,
  );
  return BiliNovelSource();
}
