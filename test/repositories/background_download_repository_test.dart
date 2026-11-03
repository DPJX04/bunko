import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/models/download_notice.dart';
import 'package:light_novel_downloader/repositories/background_download_repository.dart';

import '../support/fakes.dart';

void main() {
  late FakeBackgroundService service;
  late BackgroundDownloadRepository repository;

  const DownloadNotice first = (
    title: 'Downloading 第1卷',
    text: '0% · 1 more waiting',
    book: '酒醉就旅行的今里小姐',
    percent: 0,
  );
  const DownloadNotice later = (
    title: 'Downloading 第1卷',
    text: '50% · 1 more waiting',
    book: '酒醉就旅行的今里小姐',
    percent: 50,
  );

  setUp(() {
    service = FakeBackgroundService();
    repository = BackgroundDownloadRepository(service);
  });

  test('the first notice asks for permission and starts the service', () async {
    await repository.show(first);

    expect(service.calls, ['permission', 'start 0%']);
  });

  test('later notices update the running service', () async {
    await repository.show(first);
    await repository.show(later);

    expect(service.calls.last, 'update 50%');
  });

  test('hide stops the service once', () async {
    await repository.show(first);
    await repository.hide();
    await repository.hide();

    expect(service.calls, ['permission', 'start 0%', 'stop']);
  });

  test('hide does nothing while no notice is shown', () async {
    await repository.hide();

    expect(service.calls, isEmpty);
  });

  test('a new queue starts the service again without asking again', () async {
    await repository.show(first);
    await repository.hide();
    await repository.show(later);

    expect(service.calls, ['permission', 'start 0%', 'stop', 'start 50%']);
  });

  test('a stop asked during the first start is sent after it', () async {
    final starting = repository.show(first);
    final stopping = repository.hide();
    await Future.wait([starting, stopping]);

    expect(service.calls, ['permission', 'start 0%', 'stop']);
  });

  test('the same notice twice is sent once', () async {
    await repository.show(first);
    await repository.show(first);

    expect(service.calls, ['permission', 'start 0%']);
  });
}
