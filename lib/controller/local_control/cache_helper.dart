import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static SharedPreferences? _prefs;

  // Initialize SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Save data with different types
  static Future<bool> saveData({
    required String key,
    required dynamic value,
  }) async {
    if (_prefs == null) await init();

    if (value is String) {
      return await _prefs!.setString(key, value);
    } else if (value is int) {
      return await _prefs!.setInt(key, value);
    } else if (value is bool) {
      return await _prefs!.setBool(key, value);
    } else if (value is double) {
      return await _prefs!.setDouble(key, value);
    } else if (value is List<String>) {
      return await _prefs!.setStringList(key, value);
    }
    return false;
  }

  // Get data
  static dynamic getData({required String key}) {
    if (_prefs == null) return null;
    return _prefs!.get(key);
  }

  // Type-safe getters (return null on type mismatch instead of throwing)
  static String? getString({required String key}) {
    if (_prefs == null) return null;
    return _prefs!.getString(key);
  }

  static int? getInt({required String key}) {
    if (_prefs == null) return null;
    return _prefs!.getInt(key);
  }

  static bool? getBool({required String key}) {
    if (_prefs == null) return null;
    return _prefs!.getBool(key);
  }

  static double? getDouble({required String key}) {
    if (_prefs == null) return null;
    return _prefs!.getDouble(key);
  }

  // Remove specific data
  static Future<bool> removeData({required String key}) async {
    if (_prefs == null) await init();
    return await _prefs!.remove(key);
  }

  // Clear all data
  static Future<bool> clearAllData() async {
    if (_prefs == null) await init();
    return await _prefs!.clear();
  }

  // Check if key exists
  static bool containsKey({required String key}) {
    if (_prefs == null) return false;
    return _prefs!.containsKey(key);
  }
}
