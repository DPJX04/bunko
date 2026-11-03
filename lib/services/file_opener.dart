import 'package:flutter/services.dart';

import '../models/result.dart';
import '../utils/error_messages.dart';

/// Opens a saved EPUB in a reader app, such as eBoox.
///
/// The work is done in android/app/src/main/kotlin/.../FileOpener.kt, an
/// ACTION_VIEW intent shown in Android's "Open with" list. No package is
/// needed for that: open_filex takes file paths, not the content URIs
/// MediaStore gives, and android_intent_plus would add a plugin for one
/// call.
class FileOpener {
  static const _channel = MethodChannel('light_novel_downloader/file_opener');

  /// Opens the EPUB at [uri], a content URI from MediaStore, in the reader
  /// the user picks from Android's "Open with" list.
  Future<Result<void>> openEpub(String uri) async {
    try {
      await _channel.invokeMethod<void>('openEpub', {'uri': uri});
      return const Ok(null);
    } on PlatformException catch (error) {
      return Err(messageForOpenError(error.code));
    } catch (error) {
      return Err(messageFor(error));
    }
  }
}
