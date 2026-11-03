// Port of bili_novel_packer lib/novel_packer.dart, NovelPacker.packVolume,
// NovelPacker.packCombine and the helpers they call, at commit b75b1fb5
// (v0.2.50).
// Upstream: Copyright (c) 2023 Sparks, MIT licence. The full notice is in
// THIRD_PARTY_NOTICES.md.
//
// Changes from upstream, all because upstream is a desktop command line tool:
// - progress goes to a callback instead of the console
// - a cancel check runs before each chapter and each image
// - the EPUB is written to a path the caller gives, not the working folder
// - a failed image is logged instead of printed
// - every cover detector error is caught, so one odd image cannot fail the
//   volume (upstream catches only UnsupportedImageException, and not at all
//   around the volume cover)
// - the chapter title div is built with .text, so a title with < or & in
//   it cannot break the page
// - after packing, utils/epub_cover_meta.dart adds the EPUB 2 cover tag
//   and stores mimetype uncompressed, so readers such as eBoox show the cover
// - packCombine becomes packMerged: it packs the volumes the user ticked
//   rather than a whole book, takes its title from the caller (such as
//   'Book 2-4', so two merges of one book can be told apart), and picks its
//   cover with the same detector as a single volume, the book cover first
// - the next chapters' pages are fetched while this chapter's images
//   download, up to AppConfig.chaptersFetchedAhead chapters ahead.
//   Upstream limits text and image requests separately, so the two overlap
//   without any request coming sooner than its limit allows
// Everything else, including the image, cover and tag handling, is kept as
// upstream wrote it. When upstream changes this file, port the change here.
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:typed_data';

import 'package:bili_novel_packer/assets/assets.dart';
import 'package:bili_novel_packer/epub_packer/epub_navigator_ncx.dart';
import 'package:bili_novel_packer/epub_packer/epub_packer.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_cover_detector.dart';
import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart'
    as upstream;
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/util/html_util.dart';
import 'package:bili_novel_packer/util/sequence.dart';
import 'package:bili_novel_packer/util/volume_util.dart';
import 'package:html/dom.dart';

import '../config/app_config.dart';
import '../models/result.dart';
import '../utils/epub_cover_meta.dart';
import '../utils/error_messages.dart';

/// Reports how many of a volume's chapters are done, such as (12, 30).
typedef PackProgress = void Function(int chaptersDone, int chaptersTotal);

/// Builds one EPUB file from one upstream volume.
class VolumePacker {
  VolumePacker(this._source);

  final LightNovelSource _source;

  /// Packs [volume] into the file at [outputPath]. Returns the file, or Err
  /// with a readable reason, including when [isCancelled] turns true.
  Future<Result<File>> pack({
    required upstream.Volume volume,
    required String outputPath,
    required PackProgress onProgress,
    required bool Function() isCancelled,
  }) async {
    try {
      final run = _PackRun(EpubPacker(outputPath), isCancelled);
      await _addChapters(run, volume, onProgress);
      await _resolveCover(run, volume.cover);
      await File(outputPath).parent.create(recursive: true);
      run.epub.pack();
      final file = File(outputPath);
      await file.writeAsBytes(withEpub2CoverMeta(await file.readAsBytes()));
      return Ok(file);
    } on _Cancelled {
      return const Err(cancelled);
    } catch (error, stack) {
      developer.log('pack failed', error: error, stackTrace: stack);
      return Err(messageFor(error));
    }
  }

  /// Packs [volumes] into one EPUB called [title], with one contents entry
  /// per volume and its chapters inside it. [onProgress] counts chapters
  /// across all the volumes. Returns the file, or Err with a readable
  /// reason, including when [isCancelled] turns true.
  Future<Result<File>> packMerged({
    required List<upstream.Volume> volumes,
    required String title,
    required String outputPath,
    required PackProgress onProgress,
    required bool Function() isCancelled,
  }) async {
    try {
      final run = _PackRun(EpubPacker(outputPath), isCancelled);
      final novel = volumes.first.catalog.novel;
      _fillMergedMetadata(run.epub, novel, title);
      if (AppConfig.addChapterTitle) run.epub.addStylesheet(styleCss());
      await _addMergedChapters(run, volumes, onProgress);
      await _resolveCover(run, novel.coverUrl);
      await File(outputPath).parent.create(recursive: true);
      run.epub.pack();
      final file = File(outputPath);
      await file.writeAsBytes(withEpub2CoverMeta(await file.readAsBytes()));
      return Ok(file);
    } on _Cancelled {
      return const Err(cancelled);
    } catch (error, stack) {
      developer.log('merged pack failed', error: error, stackTrace: stack);
      return Err(messageFor(error));
    }
  }

  /// Adds every chapter of [volumes] in order, each volume a contents entry
  /// that opens at its first chapter, reporting progress after each one.
  Future<void> _addMergedChapters(
    _PackRun run,
    List<upstream.Volume> volumes,
    PackProgress onProgress,
  ) async {
    var total = 0;
    for (final volume in volumes) {
      total += volume.chapters.length;
    }
    var done = 0;
    onProgress(0, total);
    final feed = _ChapterFeed(_source, run, [
      for (final volume in volumes) ...volume.chapters,
    ]);
    for (final volume in volumes) {
      final entry = NavPoint(volume.volumeName);
      for (final chapter in volume.chapters) {
        run.stopIfCancelled();
        final page = await feed.take();
        final name = await _addChapter(run, chapter, page, addNavPoint: false);
        entry.src ??= name;
        entry.addChild(NavPoint(chapter.chapterName, src: name));
        done++;
        onProgress(done, total);
      }
      run.epub.addNavPoint(entry);
    }
  }

  /// Copies the book's title, author and tags into a merged EPUB, as
  /// upstream's _fillEpubCombine does, under [title].
  void _fillMergedMetadata(
    EpubPacker epub,
    upstream.Novel novel,
    String title,
  ) {
    epub.docTitle = title;
    epub.creator = novel.author;
    epub.source = novel.url;
    epub.publisher = novel.publisher;
    epub.subjects = novel.tags ?? [];
    epub.description = novel.description;
  }

  /// Adds the metadata and every chapter, reporting progress after each one.
  Future<void> _addChapters(
    _PackRun run,
    upstream.Volume volume,
    PackProgress onProgress,
  ) async {
    _fillMetadata(run.epub, volume);
    if (AppConfig.addChapterTitle) run.epub.addStylesheet(styleCss());
    final total = volume.chapters.length;
    onProgress(0, total);
    final feed = _ChapterFeed(_source, run, volume.chapters);
    for (var i = 0; i < total; i++) {
      run.stopIfCancelled();
      await _addChapter(run, volume.chapters[i], await feed.take());
      onProgress(i + 1, total);
    }
  }

  /// Adds one fetched chapter [page] to the EPUB, with its images. Returns
  /// its file name, such as chapter000003.xhtml. With [addNavPoint] false
  /// the caller adds its contents entry, as a merged EPUB does under each
  /// volume.
  Future<String> _addChapter(
    _PackRun run,
    upstream.Chapter chapter,
    Document page, {
    bool addNavPoint = true,
  }) async {
    final doc = await _resolveChapter(run, chapter, page);
    _addTitle(doc, chapter.chapterName);
    final id = run.chapterSeq.next.toString().padLeft(6, '0');
    run.epub.addChapter(
      name: 'OEBPS/chapter$id.xhtml',
      title: chapter.chapterName,
      chapterContent: _appendXmlDeclare(_closeTag(doc)),
      addNavPoint: addNavPoint,
    );
    return 'chapter$id.xhtml';
  }

  /// Copies the book's title, author, tags and series number into the EPUB.
  void _fillMetadata(EpubPacker epub, upstream.Volume volume) {
    final novel = volume.catalog.novel;
    epub.docTitle = volume.volumeName.startsWith(novel.title)
        ? volume.volumeName
        : '${novel.title} ${volume.volumeName}';
    epub.creator = novel.author;
    epub.source = novel.url;
    epub.publisher = novel.publisher;
    epub.subjects = novel.tags ?? [];
    epub.description = novel.description;
    // Upstream sets the series name only when it finds a volume number,
    // otherwise readers would treat every volume as number 1.
    epub.calibreSeriesIndex = VolumeUtil.getSeriesIndex(volume.volumeName);
    if (epub.calibreSeriesIndex != null) epub.calibreSeries = novel.title;
  }

  /// Stores a fetched chapter's images and adds its title. Upstream has
  /// already joined its pages and restored the paragraph order.
  Future<Document> _resolveChapter(
    _PackRun run,
    upstream.Chapter chapter,
    Document doc,
  ) async {
    await _resolveImages(run, doc);
    if (AppConfig.addChapterTitle) {
      doc.head!.append(
        Element.html(
          '<link rel="stylesheet" type="text/css" href="styles/style.css">',
        ),
      );
      final title = Element.tag('div')
        ..classes.add('chapter-title')
        ..text = chapter.chapterName;
      doc.body!.insertBefore(title, doc.body!.firstChild);
    }
    return doc;
  }

  /// Downloads every image in a chapter into the EPUB and points each img
  /// tag at its copy, so illustrations stay where they are in the text.
  /// An image that fails keeps its web address, as upstream does.
  Future<void> _resolveImages(_PackRun run, Document doc) async {
    for (final img in doc.querySelectorAll('img')) {
      run.stopIfCancelled();
      final src = img.attributes['src'];
      if (src == null || src.trim().isEmpty) continue;
      final data = await _downloadImage(src);
      if (data == null) continue;
      final relativeSrc = run.nextImageName();
      run.epub.addImage(name: 'OEBPS/$relativeSrc', data: data);
      img.attributes['src'] = relativeSrc;
      run.offerCover('OEBPS/$relativeSrc', data, first: false);
    }
    HTMLUtil.wrapDuoKanImage(doc.body!);
  }

  /// Downloads one image, or returns null so one bad image never stops the
  /// volume.
  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final data = await _source.getImage(url);
      if (data.isNotEmpty) return data;
      developer.log('$url image download was empty');
    } catch (error) {
      developer.log('$url image download failed', error: error);
    }
    return null;
  }

  /// Sets the EPUB cover: the image at [coverUrl] (the volume's or the
  /// book's cover) when its shape looks right, otherwise the illustration
  /// upstream's detector picks.
  Future<void> _resolveCover(_PackRun run, String? coverUrl) async {
    if (coverUrl != null) {
      final coverName = run.nextImageName();
      final data = await _downloadImage(coverUrl);
      if (data != null) {
        run.epub.addImage(name: 'OEBPS/$coverName', data: data);
        run.offerCover('OEBPS/$coverName', data, first: true);
      }
    }
    final cover = run.detector.detectCover();
    if (cover != null) run.epub.cover = cover.replaceFirst('OEBPS/', '');
  }

  /// Adds a <title> element to the chapter page head.
  void _addTitle(Document document, String title) {
    final element = document.createElement('title')..text = title;
    document.head?.append(element);
  }

  /// Closes img and link tags, which XHTML requires, such as <img ...>
  /// becoming <img .../>.
  String _closeTag(Document document) {
    var html = document.outerHtml;
    for (final match in RegExp('(<(?:img|link).*?)>').allMatches(html)) {
      final segment = match.group(0)!;
      if (!segment.endsWith('/>')) {
        html = html.replaceAll(segment, '${match.group(1)!}/>');
      }
    }
    return html;
  }

  /// Puts the XML declaration and doctype that EPUB readers expect on top.
  String _appendXmlDeclare(String html) {
    const xml = '<?xml version="1.0" encoding="utf-8"?>';
    const docType = '<!DOCTYPE html>';
    return '$xml\n$docType\n$html';
  }
}

/// Everything one pack run shares: the EPUB being built, the file counters,
/// the cover detector and the cancel check.
class _PackRun {
  _PackRun(this.epub, this._isCancelled);

  final EpubPacker epub;
  final bool Function() _isCancelled;
  final detector = LightNovelCoverDetector();
  final chapterSeq = Sequence();
  final imageSeq = Sequence();

  /// Stops the run by throwing [_Cancelled] once the user has cancelled.
  void stopIfCancelled() {
    if (_isCancelled()) throw const _Cancelled();
  }

  /// Returns the next image path inside the EPUB, such as images/000003.jpg.
  String nextImageName() {
    return 'images/${imageSeq.next.toString().padLeft(6, '0')}.jpg';
  }

  /// Lets the cover detector consider an image. [first] puts it ahead of
  /// the others, which upstream does for the volume's own cover.
  void offerCover(String name, Uint8List data, {required bool first}) {
    try {
      first ? detector.addFirst(name, data) : detector.add(name, data);
    } catch (error) {
      developer.log('$name skipped by the cover detector', error: error);
    }
  }
}

/// Hands out a run's chapters in order while the ones after them load:
/// each chapter's pages start loading once the chapter before has loaded,
/// up to [AppConfig.chaptersFetchedAhead] chapters past the one handed out.
/// So text keeps loading while the caller downloads images.
class _ChapterFeed {
  _ChapterFeed(this._source, this._run, this._chapters);

  final LightNovelSource _source;
  final _PackRun _run;
  final List<upstream.Chapter> _chapters;

  /// Fetches started or waiting their turn, not yet handed out, in order.
  final _queued = <Future<Document>>[];
  var _queuedCount = 0;

  /// The last fetch queued; the next one starts after it.
  Future<void> _last = Future.value();

  /// Returns the next chapter's page, with every page joined and paragraph
  /// order restored by upstream, and queues the chapters after it.
  ///
  /// One fetch runs at a time, so each chapter loads as soon as it would
  /// alone, and a fetch starts only if the run has not been cancelled. A
  /// failed fetch fails every one queued after it, and take reports it.
  /// Queued fetches are marked ignored, so when a run stops early, one that
  /// fails is not an uncaught error.
  Future<Document> take() {
    while (_queued.length <= AppConfig.chaptersFetchedAhead &&
        _queuedCount < _chapters.length) {
      final chapter = _chapters[_queuedCount++];
      final page = _last.then((_) {
        _run.stopIfCancelled();
        return _source.getNovelChapter(chapter);
      })..ignore();
      _queued.add(page);
      _last = page;
    }
    return _queued.removeAt(0);
  }
}

/// Thrown inside a pack run when the user cancels, caught in
/// [VolumePacker.pack].
class _Cancelled implements Exception {
  const _Cancelled();
}
