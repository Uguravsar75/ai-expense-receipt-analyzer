import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends ChangeNotifier {
  static const _key = 'locale_code';

  Locale _locale = const Locale('tr', 'TR');

  Locale get locale => _locale;

  LocaleNotifier() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key) ?? 'tr';
    _locale = _fromCode(code);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    _locale = _fromCode(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, languageCode);
    notifyListeners();
  }

  static Locale _fromCode(String code) {
    switch (code) {
      case 'en': return const Locale('en', 'GB');
      case 'de': return const Locale('de', 'DE');
      case 'fr': return const Locale('fr', 'FR');
      case 'ar': return const Locale('ar', 'SA');
      default:   return const Locale('tr', 'TR');
    }
  }
}
