import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyController extends ChangeNotifier {
  CurrencyController({SharedPreferences? preferences}) : _preferences = preferences;

  static const storageKey = 'currency_iso';

  SharedPreferences? _preferences;
  String _code = 'PHP';

  String get code => _code;

  Future<void> load() async {
    try {
      _preferences ??= await SharedPreferences.getInstance();
      final raw = _preferences?.getString(storageKey);
      if (raw != null && raw.isNotEmpty) {
        _code = raw.toUpperCase();
      }
      notifyListeners();
    } catch (error) {
      debugPrint('CurrencyController load failed: $error');
      _code = 'PHP';
      notifyListeners();
    }
  }

  Future<void> setCode(String code) async {
    final next = code.toUpperCase();
    if (_code == next) return;
    _code = next;
    notifyListeners();
    try {
      _preferences ??= await SharedPreferences.getInstance();
      await _preferences?.setString(storageKey, _code);
    } catch (error) {
      debugPrint('CurrencyController save failed: $error');
    }
  }
}
