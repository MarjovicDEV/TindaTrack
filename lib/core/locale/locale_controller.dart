import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends ChangeNotifier {
  LocaleController({SharedPreferences? preferences}) : _preferences = preferences;

  static const storageKey = 'app_locale';

  SharedPreferences? _preferences;
  Locale _locale = const Locale('fil');

  Locale get locale => _locale;

  Future<void> load() async {
    try {
      _preferences ??= await SharedPreferences.getInstance();
      final raw = _preferences?.getString(storageKey);
      _locale = _fromStorage(raw);
      notifyListeners();
    } catch (error) {
      debugPrint('LocaleController load failed: $error');
      _locale = const Locale('fil');
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    try {
      _preferences ??= await SharedPreferences.getInstance();
      await _preferences?.setString(storageKey, locale.languageCode);
    } catch (error) {
      debugPrint('LocaleController save failed: $error');
    }
  }

  static Locale _fromStorage(String? raw) {
    switch (raw) {
      case 'en':
        return const Locale('en');
      case 'fil':
      default:
        return const Locale('fil');
    }
  }
}
