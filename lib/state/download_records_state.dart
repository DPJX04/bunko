import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/download_record.dart';
import '../models/result.dart';
import '../repositories/downloaded_volume_repository.dart';
import 'settings_state.dart';

/// Every volume downloaded so far, oldest first. Download writes to it;
/// the picker and the Library read it.
final downloadRecordsProvider =
    AsyncNotifierProvider<DownloadRecordsState, List<DownloadRecord>>(
      DownloadRecordsState.new,
    );

/// Holds the download records loaded from the phone, adds new ones, and
/// keeps them matched to the files in the library folder.
class DownloadRecordsState extends AsyncNotifier<List<DownloadRecord>> {
  DownloadedVolumeRepository get _repository {
    return ref.read(downloadedVolumeRepositoryProvider);
  }

  /// The last change still running. Each change waits for the one before,
  /// so a record added while the files are checked is never lost.
  Future<void> _lastChange = Future.value();

  /// Runs [change] after every change started before it.
  Future<T> _inTurn<T>(Future<T> Function() change) {
    final done = _lastChange.then((_) => change());
    _lastChange = done.then((_) {}, onError: (_) {});
    return done;
  }

  /// Loads the stored records. If they cannot be read, the app carries on
  /// as if nothing was downloaded yet.
  @override
  Future<List<DownloadRecord>> build() async {
    final loaded = await _repository.loadRecords();
    return switch (loaded) {
      Ok(:final data) => data,
      Err() => const [],
    };
  }

  /// Stores [record] and shows it at once. Returns Err when the phone
  /// could not store it.
  Future<Result<void>> add(DownloadRecord record) {
    return _inTurn(() async {
      await future;
      final added = await _repository.addRecord(record);
      if (added is Ok<List<DownloadRecord>>) state = AsyncData(added.data);
      return switch (added) {
        Ok() => const Ok(null),
        Err(:final message) => Err(message),
      };
    });
  }

  /// Matches the records to the EPUBs in the library folder picked in
  /// Settings: volumes deleted or moved away leave Library and the picker,
  /// and EPUBs found there with no record join them. When the folder
  /// cannot be listed, every record stays.
  Future<void> sync() {
    return _inTurn(() async {
      await future;
      final settings = await ref.read(settingsProvider.future);
      final synced = await _repository.syncWithFolder(settings.libraryFolder);
      if (synced is Ok<List<DownloadRecord>>) state = AsyncData(synced.data);
    });
  }
}
