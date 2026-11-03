// Stand-ins for the network, MediaStore and shared_preferences, so the
// repositories and controllers run for real in tests without a phone.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart'
    as upstream;
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:light_novel_downloader/models/download_notice.dart';
import 'package:light_novel_downloader/models/download_record.dart';
import 'package:light_novel_downloader/models/library_file.dart';
import 'package:light_novel_downloader/models/result.dart';
import 'package:light_novel_downloader/repositories/background_download_repository.dart';
import 'package:light_novel_downloader/repositories/downloaded_volume_repository.dart';
import 'package:light_novel_downloader/repositories/novel_repository.dart';
import 'package:light_novel_downloader/repositories/settings_repository.dart';
import 'package:light_novel_downloader/services/background_service.dart';
import 'package:light_novel_downloader/services/download_storage.dart';
import 'package:light_novel_downloader/services/file_opener.dart';
import 'package:light_novel_downloader/services/local_store.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';

/// Keeps stored text in memory instead of shared_preferences.
class MemoryStore implements LocalStore {
  final values = <String, String>{};

  @override
  Future<Result<String?>> readString(String key) async => Ok(values[key]);

  @override
  Future<Result<void>> writeString(String key, String value) async {
    values[key] = value;
    return const Ok(null);
  }
}

/// Pretends to be the library folder: saves answer with a content URI per
/// file, and listing returns the files saved or placed there.
class FakeStorage implements DownloadStorage {
  /// Names of the files saved so far, in order.
  final saved = <String>[];

  /// The copy each save was asked to write over, or null for a new file.
  final replaced = <String?>[];

  /// The folder each save went to, null for Download/LightNovel.
  final savedTo = <String?>[];

  /// The EPUBs in the folder, as listing returns them.
  final files = <LibraryFile>[];

  /// The folder each listing was asked for, null for Download/LightNovel.
  final listed = <String?>[];

  /// True to make every listing fail.
  bool listFails = false;

  /// When set, a listing waits until it completes.
  Completer<void>? listGate;

  /// The folder [pickFolder] answers with; null is a cancelled picker.
  String? picked;

  /// Puts an EPUB in the folder, as a file manager or an earlier install
  /// would have.
  void place(String uri, {String name = 'Book_01.epub', String? opf}) {
    files.add(
      LibraryFile(
        uri: uri,
        name: name,
        modified: DateTime.utc(2026, 11, 3),
        opf: opf,
      ),
    );
  }

  /// Takes the file at [uri] out of the folder.
  void delete(String uri) => files.removeWhere((file) => file.uri == uri);

  @override
  Future<Result<String>> saveEpub(
    File epub, {
    String? replaceUri,
    String? folderUri,
  }) async {
    final name = epub.path.split('/').last;
    saved.add(name);
    replaced.add(replaceUri);
    savedTo.add(folderUri);
    // Writing over a copy keeps its URI, as MediaStore does.
    final uri =
        replaceUri ??
        'content://media/external_primary/downloads/${saved.length}';
    delete(uri);
    place(uri, name: name);
    return Ok(uri);
  }

  @override
  Future<Result<List<LibraryFile>>> listFolder({
    String? folderUri,
    required Set<String> known,
  }) async {
    listed.add(folderUri);
    await listGate?.future;
    if (listFails) return const Err(somethingWentWrong);
    return Ok(List.of(files));
  }

  @override
  Future<String?> pickFolder() async => picked;
}

/// Pretends to open saved EPUBs in a reader app, recording each URI.
///
/// Set [failure] to make every open fail with that sentence.
class FakeOpener implements FileOpener {
  final opened = <String>[];
  String? failure;

  @override
  Future<Result<void>> openEpub(String uri) async {
    opened.add(uri);
    final message = failure;
    return message == null ? const Ok(null) : Err(message);
  }
}

/// Records what the app asks of the Android background service, such as
/// 'start 0%', 'update 50%', 'stop' and 'permission'.
class FakeBackgroundService implements BackgroundService {
  final calls = <String>[];

  @override
  Future<Result<void>> requestNotificationPermission() async {
    calls.add('permission');
    return const Ok(null);
  }

  @override
  Future<Result<void>> start(DownloadNotice notice) async {
    calls.add('start ${notice.percent}%');
    return const Ok(null);
  }

  @override
  Future<Result<void>> update(DownloadNotice notice) async {
    calls.add('update ${notice.percent}%');
    return const Ok(null);
  }

  @override
  Future<Result<void>> stop() async {
    calls.add('stop');
    return const Ok(null);
  }

  @override
  void onNotificationTapped(VoidCallback onTap) {}
}

/// A linovelib book that never touches the network: [volumeCount] volumes
/// of two chapters, each chapter one page with one illustration.
///
/// Set [offline] to make every request fail as if Wi-Fi were off.
class FakeSource implements LightNovelSource {
  FakeSource({this.volumeCount = 1});

  final int volumeCount;
  bool offline = false;

  /// Volume numbers whose chapters fail as if offline, from 1.
  final failingVolumes = <int>{};

  /// While set, every chapter waits for it, so a test can act mid-download.
  Completer<void>? hold;

  /// How many times the table of contents was fetched.
  int catalogRequests = 0;

  @override
  String get name => 'fake';

  @override
  String get sourceUrl => 'https://example.test';

  @override
  bool supportUrl(String url) => true;

  @override
  Future<upstream.Novel> getNovel(String url) async {
    _failIfOffline();
    return upstream.Novel()
      ..id = '5330'
      ..title = '酒醉就旅行的今里小姐'
      ..author = '结城弘'
      ..status = 'done'
      ..url = url;
  }

  @override
  Future<upstream.Catalog> getNovelCatalog(upstream.Novel novel) async {
    _failIfOffline();
    catalogRequests++;
    final catalog = upstream.Catalog(novel);
    for (var v = 1; v <= volumeCount; v++) {
      final volume = upstream.Volume('第$v卷', catalog);
      for (var c = 1; c <= 2; c++) {
        volume.chapters.add(
          upstream.Chapter('第$c章', 'https://x.test/$v/$c', volume),
        );
      }
      catalog.volumes.add(volume);
    }
    return catalog;
  }

  @override
  Future<Document> getNovelChapter(upstream.Chapter chapter) async {
    _failIfOffline();
    await hold?.future;
    final volumeNumber = int.parse(chapter.chapterUrl!.split('/')[3]);
    if (failingVolumes.contains(volumeNumber)) {
      throw const SocketException('offline');
    }
    return parse(
      '<html><head></head><body><p>text</p>'
      '<img src="https://img.test/a.jpg"></body></html>',
    );
  }

  @override
  Future<Uint8List> getImage(String url) async {
    _failIfOffline();
    return Uint8List.fromList([1, 2, 3]);
  }

  void _failIfOffline() {
    if (offline) throw const SocketException('offline');
  }
}

/// Everything a test app needs: the fake site, storage and store, and the
/// overrides that put them behind the real repositories.
class FakeWorld {
  FakeWorld({int volumeCount = 1})
    : source = FakeSource(volumeCount: volumeCount);

  final FakeSource source;
  final storage = FakeStorage();
  final store = MemoryStore();
  final opener = FakeOpener();
  final background = FakeBackgroundService();
  final folder = Directory.systemTemp.createTempSync('novel_test');

  List<Override> get overrides => [
    novelRepositoryProvider.overrideWithValue(
      NovelRepository(source: source, workFolder: () async => folder),
    ),
    downloadedVolumeRepositoryProvider.overrideWithValue(
      DownloadedVolumeRepository(storage, store, opener),
    ),
    backgroundDownloadRepositoryProvider.overrideWithValue(
      BackgroundDownloadRepository(background),
    ),
    settingsRepositoryProvider.overrideWithValue(SettingsRepository(store)),
  ];

  /// Deletes the temporary work folder.
  void dispose() => folder.deleteSync(recursive: true);
}

/// A record for volume [number] of book 5330, downloaded at [minute].
DownloadRecord record(int number, {int minute = 0, String uri = 'uri'}) {
  return DownloadRecord(
    bookId: '5330',
    volumeNumber: number,
    bookTitle: '酒醉就旅行的今里小姐',
    volumeTitle: '第$number卷',
    fileUri: uri,
    downloadedAt: DateTime.utc(2026, 11, 1, 18, minute),
  );
}
