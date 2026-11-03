import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/utils/error_messages.dart';

/// Builds a dio error with an HTTP status, as dio does for a bad response.
DioException badResponse(int status) {
  final request = RequestOptions(path: '/');
  return DioException.badResponse(
    statusCode: status,
    requestOptions: request,
    response: Response<void>(requestOptions: request, statusCode: status),
  );
}

void main() {
  test('no connection reads as no internet', () {
    final error = DioException.connectionError(
      requestOptions: RequestOptions(path: '/'),
      reason: 'offline',
    );
    expect(messageFor(error), noInternet);
  });

  test('a raw socket error reads as no internet', () {
    expect(messageFor(const SocketException('offline')), noInternet);
  });

  test('timeouts read as too slow', () {
    final error = DioException.receiveTimeout(
      timeout: const Duration(seconds: 1),
      requestOptions: RequestOptions(path: '/'),
    );
    expect(messageFor(error), tooSlow);
  });

  test('403 and 503 read as blocked', () {
    expect(messageFor(badResponse(403)), blocked);
    expect(messageFor(badResponse(503)), blocked);
  });

  test('404 and 429 have their own sentences', () {
    expect(messageFor(badResponse(404)), notFound);
    expect(messageFor(badResponse(429)), tooManyRequests);
  });

  test('a cancelled request reads as cancelled', () {
    final error = DioException.requestCancelled(
      requestOptions: RequestOptions(path: '/'),
      reason: 'user',
    );
    expect(messageFor(error), cancelled);
  });

  test('file and format errors have their own sentences', () {
    expect(messageFor(const FileSystemException('disk full')), couldNotSave);
    expect(messageFor(const FormatException('bad html')), pageChanged);
  });

  test('anything else falls back to a generic sentence', () {
    expect(messageFor(StateError('boom')), somethingWentWrong);
  });

  test('a saved file that cannot be opened reads plainly', () {
    expect(messageForOpenError('missing'), fileMissing);
    expect(messageForOpenError('no_reader'), noReader);
    expect(messageForOpenError('anything'), somethingWentWrong);
  });
}
