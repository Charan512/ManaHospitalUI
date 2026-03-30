import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists and provides the current locale selection (English / Telugu).
/// Toggle is available in the Profile screen and updates globally instantly.
class LocaleProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _localeKey = 'selected_locale';

  String _locale = 'en'; // default: English

  String get locale => _locale;
  bool get isTelugu => _locale == 'te';

  /// Call this once at app startup to restore the user's saved preference.
  Future<void> loadSavedLocale() async {
    final saved = await _storage.read(key: _localeKey);
    if (saved != null && (saved == 'en' || saved == 'te')) {
      _locale = saved;
      notifyListeners();
    }
  }

  /// Toggle between English and Telugu. Persists to secure storage.
  Future<void> toggleLocale() async {
    _locale = _locale == 'en' ? 'te' : 'en';
    await _storage.write(key: _localeKey, value: _locale);
    notifyListeners();
  }

  /// Set a specific locale code ('en' or 'te').
  Future<void> setLocale(String code) async {
    if (code != 'en' && code != 'te') return;
    _locale = code;
    await _storage.write(key: _localeKey, value: _locale);
    notifyListeners();
  }
}
