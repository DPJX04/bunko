// Loads the app's real font into widget tests, which otherwise draw every
// glyph as a square box, so a test can check widths the phone will show.
import 'dart:io';

import 'package:flutter/services.dart';

/// Registers assets/fonts/Archivo-Variable.ttf as the 'Archivo' family.
Future<void> loadArchivo() async {
  final bytes = File('assets/fonts/Archivo-Variable.ttf').readAsBytesSync();
  final loader = FontLoader('Archivo')
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}
