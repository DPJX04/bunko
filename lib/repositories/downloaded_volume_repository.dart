import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/download_record.dart';
import '../models/result.dart';
import '../services/download_storage.dart';
import '../services/file_opener.dart';
import '../services/local_store.dart';
import '../utils/error_messages.dart';
import '../utils/library_files.dart';

/// The app's one [DownloadedVolumeRepository].
final downloadedVolumeRepositoryProvider = Provider<DownloadedVolumeRepository>(
  (ref) =>
      DownloadedVolumeRepository(DownloadStorage(), LocalStore(), FileOpener()),
);

/// Owns downloaded volumes: moves each finished EPUB into Download, keeps
/// the record of what was saved where, and opens them in a reader app.
class DownloadedVolumeRepository {
  DownloadedVolumeRepository(this._storage, this._store, [FileOpener? opener])
    : _opener = opener ?? FileOpener();

  final DownloadStorage _storage;
  final LocalStore _store;
  final FileOpener _opener;

  /// Opens the saved EPUB at [fileUri] in a reader app, or says why not.
  Future<Result<void>> open(String fileUri) => _opener.openEpub(fileUri);

  /// Where the records are stored, as one JSON list.
  static const _recordsKey = 'download_records';

  /// Saves a finished EPUB from the app cache into the library folder,
  /// [folderUri] or Download/LightNovel when null, then deletes the cache
  /// copy. Returns the saved file's content URI.
  ///
  /// A volume saved before is written over the copy its record points to,
  /// or over the file of the same name in a picked folder, so downloading
  /// it again never leaves a second file beside the first.
  Future<Result<String>> save(
    File epub, {
    required String bookId,
    required int volumeNumber,
    String? folderUri,
  }) async {
    final earlier = folderUri == null
        ? await _recordedUri(bookId, volumeNumber)
        : null;
    final saved = await _storage.saveEpub(
      epub,
      replaceUri: earlier,
      folderUri: folderUri,
    );
    if (saved is Ok<String> && epub.existsSync()) await epub.delete();
    return saved;
  }

  /// Saves an EPUB that merges several volumes into the library folder,
  /// as [save] does, then deletes the cache copy. Returns the saved file's
  /// content URI. A merge of the same volumes saved before is replaced by
  /// name.
  Future<Result<String>> saveMerged(File epub, {String? folderUri}) async {
    final saved = await _storage.saveEpub(epub, folderUri: folderUri);
    if (saved is Ok<String> && epub.existsSync()) await epub.delete();
    return saved;
  }

  /// The content URI the record of this volume points to, or null when it
  /// was never saved, the records cannot be read, or the file is a merge
  /// that other volumes share: writing one volume over it would lose them.
  Future<String?> _recordedUri(String bookId, int volumeNumber) async {
    final loaded = await loadRecords();
    if (loaded is! Ok<List<DownloadRecord>>) return null;
    final records = loaded.data;
    String? uri;
    for (final record in records) {
      if (record.bookId == bookId && record.volumeNumber == volumeNumber) {
        uri = record.fileUri;
      }
    }
    final sharers = records.where((record) => record.fileUri == uri).length;
    return sharers == 1 ? uri : null;
  }

  /// Reads every download record, oldest first. A stored entry that no
  /// longer reads as a record is skipped.
  Future<Result<List<DownloadRecord>>> loadRecords() async {
    final stored = await _store.readString(_recordsKey);
    switch (stored) {
      case Err(:final message):
        return Err(message);
      case Ok(:final data):
        if (data == null) return const Ok([]);
        return _decodeRecords(data);
    }
  }

  /// Adds [record], replacing an older record of the same volume, and
  /// returns the updated list.
  Future<Result<List<DownloadRecord>>> addRecord(DownloadRecord record) async {
    final loaded = await loadRecords();
    if (loaded is Err<List<DownloadRecord>>) return loaded;
    final records =
        (loaded as Ok<List<DownloadRecord>>).data
            .where((old) => !old.isSameVolume(record))
            .toList()
          ..add(record);
    return _writeRecords(records);
  }

  /// Matches the records to the EPUBs now in the library folder,
  /// [folderUri] or Download/LightNovel when null, stores the result and
  /// returns it: a file deleted or moved away loses its record, and a file
  /// no record describes, such as after a reinstall or in a newly picked
  /// folder, gains one read back from it. When the folder cannot be listed,
  /// the records stay as they are.
  Future<Result<List<DownloadRecord>>> syncWithFolder(String? folderUri) async {
    final loaded = await loadRecords();
    if (loaded is Err<List<DownloadRecord>>) return loaded;
    final records = (loaded as Ok<List<DownloadRecord>>).data;
    final listed = await _storage.listFolder(
      folderUri: folderUri,
      known: {for (final record in records) record.fileUri},
    );
    switch (listed) {
      case Err(:final message):
        return Err(message);
      case Ok(data: final files):
        return _writeRecords(recordsForFiles(records, files));
    }
  }

  /// Lets the owner pick a library folder in Android's folder picker.
  /// Returns its tree URI, or null when they backed out.
  Future<String?> pickFolder() => _storage.pickFolder();

  /// Stores [records] in place of the list there, and returns them.
  Future<Result<List<DownloadRecord>>> _writeRecords(
    List<DownloadRecord> records,
  ) async {
    final text = jsonEncode([for (final r in records) r.toJson()]);
    final written = await _store.writeString(_recordsKey, text);
    if (written is Err<void>) return Err(written.message);
    return Ok(records);
  }

  /// Turns the stored JSON list back into records.
  Result<List<DownloadRecord>> _decodeRecords(String text) {
    final Object? list;
    try {
      list = jsonDecode(text);
    } on FormatException catch (error) {
      return Err(messageFor(error));
    }
    if (list is! List<Object?>) return const Err(somethingWentWrong);
    final records = <DownloadRecord>[];
    for (final entry in list) {
      final record = _decodeRecord(entry);
      if (record != null) records.add(record);
    }
    return Ok(records);
  }

  /// Reads one stored entry, or returns null when it is not a valid record.
  DownloadRecord? _decodeRecord(Object? entry) {
    try {
      if (entry is Map<String, Object?>) return DownloadRecord.fromJson(entry);
    } on FormatException catch (error) {
      developer.log('download record skipped', error: error);
    }
    return null;
  }
}
