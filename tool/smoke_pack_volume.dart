// Host smoke test: downloads one real volume on this computer through the
// same repository code the app uses, then writes the EPUB to tool/out/.
//
// Run:  dart run tool/smoke_pack_volume.dart [bookId] [volumeNumber]
// Default is book 5330, volume 1, a short illustrated book. It talks to
// the real site, so expect a few minutes:
// upstream allows about 15 page and 10 image requests per minute.
import 'dart:io';

import 'package:light_novel_downloader/models/book.dart';
import 'package:light_novel_downloader/models/result.dart';
import 'package:light_novel_downloader/repositories/novel_repository.dart';
import 'package:light_novel_downloader/services/linovelib_source.dart';

Future<void> main(List<String> args) async {
  final bookId = args.isNotEmpty ? args[0] : '5330';
  final volumeNumber = args.length > 1 ? int.parse(args[1]) : 1;
  final novels = NovelRepository(
    source: createLinovelibSource(),
    workFolder: () => Directory('tool/out').create(recursive: true),
  );

  final Book book;
  switch (await novels.fetchBook(bookId)) {
    case Ok(:final data):
      book = data;
    case Err(:final message):
      _fail('fetchBook: $message');
  }
  final volumes = book.volumes;
  stdout.writeln('Book: ${book.title} by ${book.author}');
  for (final volume in volumes) {
    stdout.writeln(
      '  ${volume.number}. ${volume.title} (${volume.chapterCount} chapters)',
    );
  }

  final started = DateTime.now();
  final file = await novels.packVolume(
    volumes[volumeNumber - 1],
    onProgress: (done, total) => stdout.writeln('  chapter $done of $total'),
    isCancelled: () => false,
  );
  switch (file) {
    case Ok(:final data):
      final seconds = DateTime.now().difference(started).inSeconds;
      stdout.writeln(
        'EPUB: ${data.absolute.path} (${data.lengthSync()} bytes, ${seconds}s)',
      );
    case Err(:final message):
      _fail('packVolume: $message');
  }
}

/// Prints the reason and stops with a failing exit code.
Never _fail(String reason) {
  stderr.writeln(reason);
  exit(1);
}
