import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

/// Returns the app cache folder where EPUBs are built, creating it if needed.
///
/// Android may clear the cache when space runs low, which is fine: a file
/// only lives here until it is copied into Download.
Future<Directory> epubWorkFolder() async {
  final cache = await getApplicationCacheDirectory();
  final folder = Directory('${cache.path}/${AppConfig.workFolder}');
  return folder.create(recursive: true);
}
