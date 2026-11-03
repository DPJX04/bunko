import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    show WebResourceErrorType;

/// Turns any raw error into one plain sentence the user can act on.
///
/// This is the only place in the app that reads raw errors. Repositories
/// call it when they build an Err, and screens only show the sentence.
String messageFor(Object error) {
  if (error is DioException) return _messageForDio(error);
  if (error is SocketException) return noInternet;
  if (error is FileSystemException) return couldNotSave;
  if (error is FormatException) return pageChanged;
  return somethingWentWrong;
}

/// Turns a web view page error into one sentence, such as when offline.
String messageForPageError(WebResourceErrorType? type) {
  if (_offlineErrors.contains(type)) return noInternet;
  if (type == WebResourceErrorType.TIMEOUT) return tooSlow;
  return pageDidNotLoad;
}

/// Turns the reason Android could not open a saved file into one sentence.
/// [code] is the error code FileOpener.kt sends: 'missing' or 'no_reader'.
String messageForOpenError(String code) {
  return switch (code) {
    'missing' => fileMissing,
    'no_reader' => noReader,
    _ => somethingWentWrong,
  };
}

/// Web view errors that mean the phone cannot reach the site at all.
final _offlineErrors = {
  WebResourceErrorType.HOST_LOOKUP,
  WebResourceErrorType.CANNOT_CONNECT_TO_HOST,
  WebResourceErrorType.NOT_CONNECTED_TO_INTERNET,
  WebResourceErrorType.NETWORK_CONNECTION_LOST,
};

/// Shown when a page in the web view fails for any other reason.
const pageDidNotLoad = 'The page did not load. Tap Retry.';

/// Shown when the phone has no connection or the site cannot be reached.
/// Wi-Fi uses a non-breaking hyphen (U+2011), so it never splits across
/// two lines.
const noInternet = 'No internet connection. Check Wi‑Fi and tap Retry.';

/// Shown when the site answers too slowly.
const tooSlow = 'The site took too long to answer. Tap Retry.';

/// Shown when the site refuses the request, often a Cloudflare check.
const blocked =
    'The site blocked the request. Open the book page in Browse once, then tap Retry.';

/// Shown when the site asks the app to slow down.
const tooManyRequests = 'Too many requests. Wait a minute, then tap Retry.';

/// Shown when a page the app asked for does not exist.
const notFound = 'This page was not found on the site.';

/// Shown when the site's HTML no longer matches what the scraper expects.
const pageChanged =
    'The site page looked different than expected. The app may need an update.';

/// Shown when writing the EPUB to the phone fails.
const couldNotSave = 'Could not save the file. Check free space on the phone.';

/// Shown when a saved volume's file was deleted or moved.
const fileMissing =
    'This file is no longer in Download/LightNovel. Download the volume again.';

/// Shown when no app on the phone opens EPUB files.
const noReader =
    'No app on this phone opens EPUB files. Install a reader such as eBoox.';

/// Shown when the user cancelled the request.
const cancelled = 'Cancelled.';

/// Shown for anything not listed above.
const somethingWentWrong = 'Something went wrong. Tap Retry.';

/// Picks the sentence for a dio failure from its type and HTTP status.
String _messageForDio(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionError:
      return noInternet;
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return tooSlow;
    case DioExceptionType.cancel:
      return cancelled;
    case DioExceptionType.badResponse:
      return _messageForStatus(error.response?.statusCode);
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return error.error is SocketException ? noInternet : somethingWentWrong;
  }
}

/// Picks the sentence for an HTTP error status, such as 403 or 404.
String _messageForStatus(int? status) {
  if (status == 403 || status == 503) return blocked;
  if (status == 404) return notFound;
  if (status == 429) return tooManyRequests;
  return somethingWentWrong;
}
