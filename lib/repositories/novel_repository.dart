import 'dart:io';

import 'package:bili_novel_packer/light_novel/base/light_novel_model.dart'
    as upstream;
import 'package:bili_novel_packer/light_novel/base/light_novel_source.dart';
import 'package:bili_novel_packer/light_novel/bili_novel/bili_novel_source.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../models/book.dart';
import '../models/result.dart';
import '../models/volume.dart';
import '../services/cache_folder.dart';
import '../services/linovelib_source.dart';
import '../utils/epub_file_name.dart';
import '../utils/error_messages.dart';
import 'volume_packer.dart';

/// The app's one [NovelRepository].
final novelRepositoryProvider = Provider<NovelRepository>(
  (ref) => NovelRepository(
    source: ref.watch(linovelibSourceProvider),
    workFolder: epubWorkFolder,
  ),
);

/// Owns linovelib books for the app: their volume lists and volume EPUBs.
///
/// bili_novel_packer's own models stay inside this file and volume_packer,
/// so a change upstream never reaches a screen.
class NovelRepository {
  NovelRepository({required LightNovelSource source, required this._workFolder})
    : _source = source,
      _packer = VolumePacker(source);

  final LightNovelSource _source;
  final VolumePacker _packer;
  final Future<Directory> Function() _workFolder;

  /// Upstream catalogs by book id, kept so a volume can be packed later.
  final _catalogs = <String, upstream.Catalog>{};

  /// The User-Agent the web view sends, the same one upstream downloads
  /// with, so the site sees one browser for browsing and downloading.
  String get browserUserAgent => BiliNovelSource.userAgent;

  /// Fetches a book and its volume list by book id, such as '2356'.
  Future<Result<Book>> fetchBook(String bookId) async {
    try {
      final novel = await _source.getNovel(AppConfig.bookUrl(bookId));
      final catalog = await _source.getNovelCatalog(novel);
      _catalogs[bookId] = catalog;
      return Ok(_toBook(bookId, catalog));
    } catch (error) {
      return Err(messageFor(error));
    }
  }

  /// Builds the EPUB for one volume in the app cache. [fetchBook] must have
  /// returned the volume's book first.
  Future<Result<File>> packVolume(
    Volume volume, {
    required PackProgress onProgress,
    required bool Function() isCancelled,
  }) async {
    final catalog = _catalogs[volume.bookId];
    if (catalog == null) return const Err(somethingWentWrong);
    final folder = await _workFolder();
    final fileName = epubFileName(
      bookTitle: catalog.novel.title,
      volumeNumber: volume.number,
      volumeTitle: volume.title,
    );
    return _packer.pack(
      volume: catalog.volumes[volume.number - 1],
      outputPath: '${folder.path}/$fileName',
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
  }

  /// Builds the EPUB for [volumes] in the app cache: one volume as
  /// [packVolume] does, several merged into one file called, for example,
  /// 'Book 2-4'. [fetchBook] must have returned their book first.
  Future<Result<File>> packVolumes(
    List<Volume> volumes, {
    required PackProgress onProgress,
    required bool Function() isCancelled,
  }) async {
    if (volumes.length == 1) {
      return packVolume(
        volumes.single,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
    }
    final catalog = _catalogs[volumes.first.bookId];
    if (catalog == null) return const Err(somethingWentWrong);
    final folder = await _workFolder();
    final first = volumes.first.number;
    final last = volumes.last.number;
    final fileName = mergedEpubFileName(
      bookTitle: catalog.novel.title,
      firstNumber: first,
      lastNumber: last,
    );
    return _packer.packMerged(
      volumes: [for (final v in volumes) catalog.volumes[v.number - 1]],
      title: '${catalog.novel.title} $first-$last',
      outputPath: '${folder.path}/$fileName',
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
  }

  /// Maps an upstream catalog to the app's Book, numbering volumes from 1.
  Book _toBook(String bookId, upstream.Catalog catalog) {
    final novel = catalog.novel;
    final volumes = <Volume>[];
    for (var i = 0; i < catalog.volumes.length; i++) {
      final volume = catalog.volumes[i];
      volumes.add(
        Volume(
          bookId: bookId,
          number: i + 1,
          title: volume.volumeName,
          chapterCount: volume.chapters.length,
        ),
      );
    }
    return Book(
      bookId: bookId,
      title: novel.title,
      author: novel.author,
      coverUrl: novel.coverUrl,
      volumes: volumes,
    );
  }
}
