import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/download_notice.dart';
import '../models/result.dart';
import '../services/background_service.dart';

/// The app's one [BackgroundDownloadRepository].
final backgroundDownloadRepositoryProvider =
    Provider<BackgroundDownloadRepository>(
      (ref) => BackgroundDownloadRepository(BackgroundService()),
    );

/// Keeps downloads running in the background while the queue has work:
/// shows the progress notice, and takes it away when the queue is done.
class BackgroundDownloadRepository {
  BackgroundDownloadRepository(this._service);

  final BackgroundService _service;

  /// The notice on screen now, or null while the service is stopped.
  DownloadNotice? _shown;

  /// Whether the notification permission was asked for in this app run.
  var _hasAsked = false;

  /// The last service call sent; the next one waits for it.
  Future<void> _pending = Future.value();

  /// Shows [notice], starting the background service when it is stopped.
  /// The first start in an app run asks for the notification permission;
  /// downloads run whatever the answer. A notice already shown is not sent
  /// again.
  Future<void> show(DownloadNotice notice) {
    if (notice == _shown) return _pending;
    final isRunning = _shown != null;
    _shown = notice;
    if (isRunning) return _send(() => _service.update(notice));
    if (!_hasAsked) {
      _hasAsked = true;
      _send(_service.requestNotificationPermission);
    }
    return _send(() => _service.start(notice));
  }

  /// Stops the background service and its notice, if they run.
  Future<void> hide() {
    if (_shown == null) return _pending;
    _shown = null;
    return _send(_service.stop);
  }

  /// Sends one call to the service after the ones before it, so a stop
  /// never overtakes the start it follows. A failed call is logged and the
  /// queue carries on: downloads run in the app itself, and the service
  /// only keeps the app awake.
  Future<void> _send(Future<Result<void>> Function() call) {
    _pending = _pending.then((_) async {
      final result = await call();
      if (result is Err<void>) {
        developer.log('background service: ${result.message}');
      }
    });
    return _pending;
  }
}
