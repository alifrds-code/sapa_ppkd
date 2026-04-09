import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

// Simpan & ambil settingan tema (dark/light) dari HP
class ThemeStorage {
  static const String _themeKey = 'is_dark_mode';

  static Future<void> saveTheme(bool isDark) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }

  static Future<bool> getTheme() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_themeKey) ?? false; // Default: Light Mode
  }
}

// Provider buat ngatur tema dark/light di seluruh aplikasi
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider(bool isDark) {
    _isDarkMode = isDark;
  }

  // Toggle antara dark mode dan light mode
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await ThemeStorage.saveTheme(_isDarkMode);
    notifyListeners();
  }
}
