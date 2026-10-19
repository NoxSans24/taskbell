import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String themePreferenceKey = 'theme_mode';

class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(themePreferenceKey);
      if (!mounted) return;
      state = _parse(stored);
    } catch (_) {
      // Preferensi sistem dipakai bila penyimpanan tidak tersedia.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(themePreferenceKey, mode.name);
    } catch (_) {
      // Preferensi tetap berlaku untuk sesi berjalan.
    }
  }

  ThemeMode _parse(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeMode>((ref) {
  return ThemeController();
});
