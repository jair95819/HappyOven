import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _themeKey = 'theme_mode';
  static ThemeMode currentMode = ThemeMode.light;

  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey) ?? false;
    currentMode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = currentMode;
  }

  Future<void> toggleTheme(bool isDark) async {
    currentMode = isDark ? ThemeMode.dark : ThemeMode.light;
    state = currentMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, isDark);
  }
}
