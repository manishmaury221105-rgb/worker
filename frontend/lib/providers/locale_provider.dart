import 'package:flutter/material.dart';
import '../core/localization/app_translations.dart';
import '../core/services/storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  String _currentLocale = 'en';

  String get currentLocale => _currentLocale;
  bool get isHindi => _currentLocale == 'hi';

  LocaleProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    _currentLocale = await StorageService.getLocale();
    notifyListeners();
  }

  Future<void> setLocale(String localeCode) async {
    if (_currentLocale == localeCode) return;
    _currentLocale = localeCode;
    await StorageService.saveLocale(localeCode);
    notifyListeners();
  }

  void toggleLocale() {
    setLocale(_currentLocale == 'en' ? 'hi' : 'en');
  }

  String tr(String key) {
    return AppTranslations.get(key, locale: _currentLocale);
  }
}
