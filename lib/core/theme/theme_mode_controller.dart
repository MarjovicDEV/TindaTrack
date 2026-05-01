import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeModeController extends ChangeNotifier {
  ThemeModeController({SharedPreferences? preferences})
    : _preferences = preferences;

  static const storageKey = 'theme_mode';

  SharedPreferences? _preferences;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    try {
      _preferences ??= await SharedPreferences.getInstance();
      final raw = _preferences?.getString(storageKey);
      _themeMode = _fromStorage(raw);
      notifyListeners();
    } catch (error) {
      debugPrint('ThemeModeController load failed: $error');
      _themeMode = ThemeMode.system;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }

    _themeMode = mode;
    notifyListeners();

    try {
      _preferences ??= await SharedPreferences.getInstance();
      await _preferences?.setString(storageKey, _toStorage(mode));
    } catch (error) {
      debugPrint('ThemeModeController save failed: $error');
    }
  }

  static String _toStorage(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _fromStorage(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
