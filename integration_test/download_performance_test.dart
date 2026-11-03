// Measures whether the UI stays smooth while a real volume downloads.
//
// Downloads book 5330 volume 1 from the site and saves it to
// Download/LightNovel, so it takes about 5 minutes. Run on the phone:
//   flutter drive --profile --driver=test_driver/perf_driver.dart \
//     --target=integration_test/download_performance_test.dart -d <serial>
// Results land in build/integration_response_data.json: frame times under
// 'download_frames', and the longest UI thread stalls under 'ui_thread_lag'.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:light_novel_downloader/app.dart';
import 'package:light_novel_downloader/features/download/download_queue_controller.dart';
import 'package:light_novel_downloader/features/download/download_task.dart';
import 'package:light_novel_downloader/models/book.dart';
import 'package:light_novel_downloader/models/result.dart';
import 'package:light_novel_downloader/repositories/novel_repository.dart';
import 'package:light_novel_downloader/routing/app_router.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // Draw every frame the app asks for, as on a normal run.
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets(
    'downloading book 5330 keeps the UI responsive',
    (tester) async {
      await tester.pumpWidget(
        const _AlwaysAnimating(child: ProviderScope(child: App())),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(App)),
      );
      appRouter.go('/downloads');
      final fetched = await container
          .read(novelRepositoryProvider)
          .fetchBook('5330');
      final book = (fetched as Ok<Book>).data;

      final probe = _LagProbe(() => _whereIs(container))..start();
      await binding.watchPerformance(() async {
        container
            .read(downloadQueueProvider.notifier)
            .add(book.volumes.first, book.title);
        await _untilSettled(container);
      }, reportKey: 'download_frames');
      probe.stop();
      binding.reportData!['ui_thread_lag'] = probe.summary();

      final task = container.read(downloadQueueProvider).single;
      expect(task.errorMessage, isNull);
      expect(task.status, DownloadStatus.done);
    },
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

/// Waits until every row on the Downloads tab is saved or failed.
Future<void> _untilSettled(ProviderContainer container) async {
  bool isSettled() {
    return container.read(downloadQueueProvider).every((task) {
      return task.status == DownloadStatus.done ||
          task.status == DownloadStatus.failed;
    });
  }

  while (!isSettled()) {
    await Future<void>.delayed(const Duration(seconds: 1));
  }
}

/// Where the download stands, such as 'downloading 3/8'.
String _whereIs(ProviderContainer container) {
  final tasks = container.read(downloadQueueProvider);
  if (tasks.isEmpty) return 'not started';
  final task = tasks.single;
  return '${task.status.name} ${task.chaptersDone}/${task.chaptersTotal}';
}

/// Keeps a thin indeterminate line moving on top of the app, so a frame
/// is due on every vsync and any stall of the UI thread shows up as a
/// missed frame.
class _AlwaysAnimating extends StatelessWidget {
  const _AlwaysAnimating({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        fit: StackFit.expand,
        children: [
          child,
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
        ],
      ),
    );
  }
}

/// Ticks every 8 ms on the UI thread and records how late each tick came:
/// a late tick means the thread was busy and could not draw. Stalls over
/// 40 ms are kept with the second they happened and [_where] at the time.
class _LagProbe {
  _LagProbe(this._where);

  static const _interval = Duration(milliseconds: 8);

  final String Function() _where;
  final _clock = Stopwatch();
  final _lagsMs = <int>[];
  final _stalls = <String>[];
  Timer? _timer;
  var _last = Duration.zero;

  /// Starts ticking.
  void start() {
    _clock.start();
    _timer = Timer.periodic(_interval, (_) {
      final now = _clock.elapsed;
      final lag = (now - _last - _interval).inMilliseconds;
      _lagsMs.add(lag);
      if (lag > 40) _stalls.add('${lag}ms at ${now.inSeconds}s, ${_where()}');
      _last = now;
    });
  }

  /// Stops ticking.
  void stop() => _timer?.cancel();

  /// The worst stalls, how many passed 50 and 100 ms, and each stall's
  /// time and place.
  Map<String, Object> summary() {
    final sorted = [..._lagsMs]..sort((a, b) => b.compareTo(a));
    return {
      'ticks': _lagsMs.length,
      'worst_ms': sorted.take(10).toList(),
      'over_50ms': _lagsMs.where((lag) => lag > 50).length,
      'over_100ms': _lagsMs.where((lag) => lag > 100).length,
      'stalls': _stalls,
    };
  }
}
