import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:light_novel_downloader/config/app_config.dart';
import 'package:light_novel_downloader/models/result.dart';
import 'package:light_novel_downloader/repositories/volume_packer.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';

/// A source that never touches the network: every chapter is the same page
/// with one good and one broken illustration.
class FakeSource implements LightNovelSource {
  @override
  String get name => 'fake';

  @override
  String get sourceUrl => 'https://example.test';

  @override
  bool supportUrl(String url) => true;

  @override
  Future<Novel> getNovel(String url) => throw UnimplementedError();

  @override
  Future<Catalog> getNovelCatalog(Novel novel) => throw UnimplementedError();

  @override
  Future<Document> getNovelChapter(Chapter chapter) async {
    return parse(
      '<html><head></head><body><p>first</p>'
      '<img src="https://img.test/good.jpg"><p>second</p>'
      '<img src="https://img.test/broken.jpg"></body></html>',
    );
  }

  @override
  Future<Uint8List> getImage(String url) async {
    if (url.contains('broken')) throw const SocketException('offline');
    return Uint8List.fromList([1, 2, 3]);
  }
}

/// A [FakeSource] whose images wait until the test lets them through, and
/// which logs each chapter fetch, so a test can see what overlaps.
class GatedSource extends FakeSource {
  /// Each fetched chapter, as 'Volume 1 Chapter 2'.
  final fetched = <String>[];

  /// Images download once this completes.
  final images = Completer<void>();

  /// Chapters whose fetch fails, by name, such as 'Chapter 2'.
  final failing = <String>{};

  @override
  Future<Document> getNovelChapter(Chapter chapter) async {
    fetched.add('${chapter.volume.volumeName} ${chapter.chapterName}');
    if (failing.contains(chapter.chapterName)) {
      throw const SocketException('offline');
    }
    return super.getNovelChapter(chapter);
  }

  @override
  Future<Uint8List> getImage(String url) async {
    await images.future;
    return super.getImage(url);
  }
}

/// A [FakeSource] whose chapter fetches each wait until the test releases
/// them by name, such as `held['Chapter 2']!.complete()`, so a test can see
/// which fetches have started.
class HeldSource extends FakeSource {
  final held = <String, Completer<void>>{};

  @override
  Future<Document> getNovelChapter(Chapter chapter) async {
    final gate = held[chapter.chapterName] = Completer<void>();
    await gate.future;
    return super.getNovelChapter(chapter);
  }
}

/// Builds an upstream volume with [chapterCount] chapters, named [name].
Volume fakeVolume(int chapterCount, {String name = 'Volume 1'}) {
  final novel = Novel()
    ..id = '1'
    ..title = 'Book'
    ..author = 'Author'
    ..status = 'done';
  final volume = Volume(name, Catalog(novel));
  for (var i = 1; i <= chapterCount; i++) {
    volume.chapters.add(Chapter('Chapter $i', 'https://x.test/$i', volume));
  }
  return volume;
}

/// Reads one file inside a packed EPUB as text.
String readEntry(File epub, String name) {
  final archive = ZipDecoder().decodeBytes(epub.readAsBytesSync());
  return utf8.decode(archive.findFile(name)!.content);
}

void main() {
  late Directory folder;

  setUp(() => folder = Directory.systemTemp.createTempSync('packer_test'));
  tearDown(() => folder.deleteSync(recursive: true));

  test('keeps illustrations inline and reports each chapter', () async {
    final progress = <String>[];
    final result = await VolumePacker(FakeSource()).pack(
      volume: fakeVolume(2),
      outputPath: '${folder.path}/out/book.epub',
      onProgress: (done, total) => progress.add('$done/$total'),
      isCancelled: () => false,
    );

    final epub = (result as Ok<File>).data;
    final chapter = readEntry(epub, 'OEBPS/chapter000001.xhtml');
    expect(progress, ['0/2', '1/2', '2/2']);
    expect(chapter.indexOf('first'), lessThan(chapter.indexOf('images/')));
    expect(chapter.indexOf('images/'), lessThan(chapter.indexOf('second')));
    expect(chapter, contains('<div class="chapter-title">Chapter 1</div>'));
  });

  test('a broken image keeps its web address and does not fail', () async {
    final result = await VolumePacker(FakeSource()).pack(
      volume: fakeVolume(1),
      outputPath: '${folder.path}/book.epub',
      onProgress: (_, _) {},
      isCancelled: () => false,
    );

    final chapter = readEntry(
      (result as Ok<File>).data,
      'OEBPS/chapter000001.xhtml',
    );
    expect(chapter, contains('https://img.test/broken.jpg'));
  });

  test('cancelling returns Err and writes no file', () async {
    final result = await VolumePacker(FakeSource()).pack(
      volume: fakeVolume(3),
      outputPath: '${folder.path}/book.epub',
      onProgress: (_, _) {},
      isCancelled: () => true,
    );

    expect((result as Err<File>).message, cancelled);
    expect(File('${folder.path}/book.epub').existsSync(), isFalse);
  });

  test(
    'merges volumes into one EPUB with a contents entry per volume',
    () async {
      final progress = <String>[];
      final result = await VolumePacker(FakeSource()).packMerged(
        volumes: [
          fakeVolume(2, name: 'Volume 2'),
          fakeVolume(1, name: 'Volume 3'),
        ],
        title: 'Book 2-3',
        outputPath: '${folder.path}/merged.epub',
        onProgress: (done, total) => progress.add('$done/$total'),
        isCancelled: () => false,
      );

      final epub = (result as Ok<File>).data;
      expect(progress, ['0/3', '1/3', '2/3', '3/3']);
      expect(
        readEntry(epub, 'OEBPS/chapter000003.xhtml'),
        contains('Chapter 1'),
      );
      final contents = readEntry(epub, 'OEBPS/toc.ncx');
      expect(contents, contains('Volume 2'));
      expect(contents, contains('Volume 3'));
      expect(
        contents.indexOf('Volume 2'),
        lessThan(contents.indexOf('Volume 3')),
      );
      expect(readEntry(epub, 'OEBPS/content.opf'), contains('Book 2-3'));
    },
  );

  test("fetches chapters ahead while this one's images download", () async {
    const ahead = AppConfig.chaptersFetchedAhead;
    final source = GatedSource();
    final packing = VolumePacker(source).pack(
      volume: fakeVolume(ahead + 3),
      outputPath: '${folder.path}/book.epub',
      onProgress: (_, _) {},
      isCancelled: () => false,
    );

    await pumpEventQueue();
    expect(source.fetched, [
      for (var i = 1; i <= ahead + 1; i++) 'Volume 1 Chapter $i',
    ]);
    source.images.complete();
    final epub = ((await packing) as Ok<File>).data;
    expect(source.fetched, hasLength(ahead + 3));
    expect(
      readEntry(epub, 'OEBPS/chapter${'${ahead + 3}'.padLeft(6, '0')}.xhtml'),
      contains('Chapter ${ahead + 3}'),
    );
  });

  test('fetches no further chapter once cancelled', () async {
    final source = HeldSource();
    var cancel = false;
    final packing = VolumePacker(source).pack(
      volume: fakeVolume(4),
      outputPath: '${folder.path}/book.epub',
      onProgress: (_, _) {},
      isCancelled: () => cancel,
    );

    await pumpEventQueue();
    source.held['Chapter 1']!.complete();
    await pumpEventQueue();
    cancel = true;
    source.held['Chapter 2']!.complete();
    expect(((await packing) as Err<File>).message, cancelled);
    await pumpEventQueue();
    expect(source.held.keys, ['Chapter 1', 'Chapter 2']);
  });

  test('a merge fetches ahead across the volume boundary', () async {
    final source = GatedSource();
    final packing = VolumePacker(source).packMerged(
      volumes: [
        fakeVolume(1),
        fakeVolume(1, name: 'Volume 2'),
      ],
      title: 'Book 1-2',
      outputPath: '${folder.path}/merged.epub',
      onProgress: (_, _) {},
      isCancelled: () => false,
    );

    await pumpEventQueue();
    expect(source.fetched, ['Volume 1 Chapter 1', 'Volume 2 Chapter 1']);
    source.images.complete();
    expect(await packing, isA<Ok<File>>());
  });

  test('a chapter fetched ahead that fails still fails the volume', () async {
    final source = GatedSource()..failing.add('Chapter 2');
    source.images.complete();
    final result = await VolumePacker(source).pack(
      volume: fakeVolume(2),
      outputPath: '${folder.path}/book.epub',
      onProgress: (_, _) {},
      isCancelled: () => false,
    );

    expect(result, isA<Err<File>>());
    expect(File('${folder.path}/book.epub').existsSync(), isFalse);
  });

  test('a fetch ahead that fails after a cancel stays quiet', () async {
    final source = GatedSource()..failing.add('Chapter 2');
    var cancel = false;
    final packing = VolumePacker(source).pack(
      volume: fakeVolume(2),
      outputPath: '${folder.path}/book.epub',
      onProgress: (_, _) {},
      isCancelled: () => cancel,
    );

    await pumpEventQueue();
    cancel = true;
    source.images.complete();
    expect(((await packing) as Err<File>).message, cancelled);
  });

  test('cancelling a merge returns Err and writes no file', () async {
    final result = await VolumePacker(FakeSource()).packMerged(
      volumes: [fakeVolume(2), fakeVolume(2)],
      title: 'Book',
      outputPath: '${folder.path}/merged.epub',
      onProgress: (_, _) {},
      isCancelled: () => true,
    );

    expect((result as Err<File>).message, cancelled);
    expect(File('${folder.path}/merged.epub').existsSync(), isFalse);
  });
}
