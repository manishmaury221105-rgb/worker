import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadSavedTheme();
  }

  Future<void> _loadSavedTheme() async {
    _isDarkMode = await StorageService.getThemeMode();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await StorageService.saveThemeMode(_isDarkMode);
    notifyListeners();
  }

  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    await StorageService.saveThemeMode(isDark);
    notifyListeners();
  }
}
