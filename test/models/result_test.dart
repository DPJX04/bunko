import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_downloader/models/result.dart';

/// Reads a result the way the app will: a switch that must cover both cases.
String describe(Result<int> result) {
  return switch (result) {
    Ok(:final data) => 'ok $data',
    Err(:final message) => 'err $message',
  };
}

void main() {
  test('Ok carries its data', () {
    expect(describe(const Ok(3)), 'ok 3');
  });

  test('Err carries its message', () {
    expect(describe(const Err('No internet')), 'err No internet');
  });
}
