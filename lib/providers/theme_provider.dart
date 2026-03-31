import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;

  bool get isDarkMode => themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    toggleTheme(
        (await SharedPreferences.getInstance()).getBool('isDarkMode') ?? true);
  }

  void toggleTheme(bool isDark) async {
    themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    (await SharedPreferences.getInstance()).setBool('isDarkMode', isDark);
    notifyListeners();
  }
}
