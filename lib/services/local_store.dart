import 'package:shared_preferences/shared_preferences.dart';

import '../models/result.dart';
import '../utils/error_messages.dart';

/// Small text values kept on the phone between app starts, through
/// shared_preferences.
class LocalStore {
  final _prefs = SharedPreferencesAsync();

  /// Reads the text stored under [key], or null when nothing is stored.
  Future<Result<String?>> readString(String key) async {
    try {
      return Ok(await _prefs.getString(key));
    } catch (error) {
      return Err(messageFor(error));
    }
  }

  /// Stores [value] under [key], replacing what was there.
  Future<Result<void>> writeString(String key, String value) async {
    try {
      await _prefs.setString(key, value);
      return const Ok(null);
    } catch (error) {
      return Err(messageFor(error));
    }
  }
}
