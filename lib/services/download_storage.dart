import 'dart:io';

import 'package:flutter/services.dart';

import '../config/app_config.dart';
import '../models/library_file.dart';
import '../models/result.dart';
import '../utils/error_messages.dart';

/// The library folder on the phone: saves finished EPUBs into it, lists
/// the EPUBs in it, and lets the owner pick it. The default folder,
/// Download/LightNovel, goes through Android MediaStore; a folder the owner
/// picked goes through the Storage Access Framework.
///
/// The work runs in android/app/src/main/kotlin/.../DownloadStorage.kt and
/// LibraryFolder.kt.
/// No package fits here yet: file_saver needs a newer Flutter than 3.44.8,
/// and media_store_plus is no longer maintained.
class DownloadStorage {
  static const _channel = MethodChannel(
    'light_novel_downloader/download_storage',
  );

  /// Copies [epub] into the library folder under the same file name and
  /// returns the saved file's content URI: Download/LightNovel, or the
  /// folder at [folderUri] when the owner picked one, where a file of the
  /// same name is written over.
  ///
  /// With [replaceUri], an earlier copy this app saved in Download is
  /// written over in place and keeps its name and URI. When that copy is
  /// gone or no longer this app's, such as after a reinstall, a new file is
  /// saved instead.
  Future<Result<String>> saveEpub(
    File epub, {
    String? replaceUri,
    String? folderUri,
  }) async {
    try {
      final uri = await _channel.invokeMethod<String>(
        folderUri == null ? 'saveToDownloads' : 'saveToFolder',
        {
          'sourcePath': epub.path,
          'folder': AppConfig.downloadFolder,
          'folderUri': folderUri,
          'fileName': epub.path.split('/').last,
          'mimeType': 'application/epub+zip',
          'replaceUri': replaceUri,
        },
      );
      return uri == null ? const Err(couldNotSave) : Ok(uri);
    } on PlatformException {
      return const Err(couldNotSave);
    } on MissingPluginException {
      return const Err(couldNotSave);
    }
  }

  /// Lists the EPUBs in the library folder: Download/LightNovel, where
  /// Android shows this install only the files it saved, or the folder at
  /// [folderUri]. The package file is read only for files whose URI is not
  /// in [known].
  Future<Result<List<LibraryFile>>> listFolder({
    String? folderUri,
    required Set<String> known,
  }) async {
    try {
      final rows = await _channel
          .invokeListMethod<Map<Object?, Object?>>('listLibrary', {
            'folderUri': folderUri,
            'folder': AppConfig.downloadFolder,
            'known': known.toList(),
          });
      return Ok([
        for (final row in rows ?? const <Map<Object?, Object?>>[])
          LibraryFile(
            uri: row['uri']! as String,
            name: row['name']! as String,
            modified: DateTime.fromMillisecondsSinceEpoch(
              row['modified']! as int,
            ),
            opf: row['opf'] as String?,
          ),
      ]);
    } on PlatformException {
      return const Err(somethingWentWrong);
    } on MissingPluginException {
      return const Err(somethingWentWrong);
    }
  }

  /// Opens Android's folder picker at Download/LightNovel and returns the
  /// folder the owner picked, as a tree URI this app may keep using, or
  /// null when they backed out.
  Future<String?> pickFolder() async {
    try {
      return await _channel.invokeMethod<String>('pickLibraryFolder', {
        'folder': AppConfig.downloadFolder,
      });
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
