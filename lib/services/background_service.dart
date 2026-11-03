import 'package:flutter/services.dart';

import '../models/download_notice.dart';
import '../models/result.dart';
import '../utils/error_messages.dart';

/// Runs the Android foreground service that keeps the app alive while
/// downloads run in the background, with its progress notification.
///
/// The service itself is android/app/src/main/kotlin/.../DownloadService.kt.
/// No package fits: flutter_foreground_task, the maintained choice, has no
/// notification progress bar and starts a second Flutter engine beside the
/// web view (owner's choice, 2026-11-02).
class BackgroundService {
  static const _channel = MethodChannel('light_novel_downloader/background');

  /// Asks for the notification permission Android 13 and newer need, and
  /// returns without waiting for the answer. The service runs either way;
  /// without it the notice only shows in the system's task manager.
  Future<Result<void>> requestNotificationPermission() {
    return _call('requestNotificationPermission');
  }

  /// Starts the service with its first notice. Call it while the app is on
  /// screen: Android refuses to start one from the background.
  Future<Result<void>> start(DownloadNotice notice) {
    return _call('start', _arguments(notice));
  }

  /// Shows a new notice on the running service.
  Future<Result<void>> update(DownloadNotice notice) {
    return _call('update', _arguments(notice));
  }

  /// Stops the service and removes its notice.
  Future<Result<void>> stop() => _call('stop');

  /// Calls [onTap] whenever the user taps the notice.
  void onNotificationTapped(VoidCallback onTap) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openDownloads') onTap();
    });
  }

  /// Calls [method] on the Kotlin side.
  Future<Result<void>> _call(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      await _channel.invokeMethod<void>(method, arguments);
      return const Ok(null);
    } catch (error) {
      return Err(messageFor(error));
    }
  }

  /// The notice as channel arguments; DownloadService.kt reads these keys.
  Map<String, Object?> _arguments(DownloadNotice notice) {
    return {
      'title': notice.title,
      'text': notice.text,
      'book': notice.book,
      'percent': notice.percent,
    };
  }
}
