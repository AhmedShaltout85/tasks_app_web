import 'package:flutter/material.dart';
import 'package:tasks_app/controller/local_control/cache_helper.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  static const String _themeCacheKey = 'theme_mode';

  ThemeProvider() {
    _loadTheme();
  }

  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  // Load saved theme from cache
  Future<void> _loadTheme() async {
    final savedTheme = CacheHelper.getData(key: _themeCacheKey);

    if (savedTheme != null) {
      if (savedTheme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (savedTheme == 'light') {
        _themeMode = ThemeMode.light;
      } else if (savedTheme == 'system') {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    }
  }

  // Set theme and save to cache
  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;

    // Save theme to cache
    String themeString;
    if (mode == ThemeMode.dark) {
      themeString = 'dark';
    } else if (mode == ThemeMode.light) {
      themeString = 'light';
    } else {
      themeString = 'system';
    }

    await CacheHelper.saveData(key: _themeCacheKey, value: themeString);
    notifyListeners();
  }

  // Toggle between light and dark
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setTheme(ThemeMode.dark);
    } else {
      await setTheme(ThemeMode.light);
    }
  }
}
