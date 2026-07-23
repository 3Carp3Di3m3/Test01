import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide toggles, persisted in shared_preferences.
class AppSettings extends ChangeNotifier {
  static const _soundKey = 'settings_sound';
  static const _vibrationKey = 'settings_vibration';
  static const _keepAwakeKey = 'settings_keep_awake';
  static const _voiceKey = 'settings_voice';
  static const _themeKey = 'settings_theme_mode';

  bool _sound = true;
  bool _vibration = true;
  bool _keepAwake = true;
  bool _voice = true;
  ThemeMode _themeMode = ThemeMode.system;

  bool get soundEnabled => _sound;
  bool get vibrationEnabled => _vibration;
  bool get keepAwakeEnabled => _keepAwake;
  bool get voiceEnabled => _voice;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _sound = prefs.getBool(_soundKey) ?? true;
    _vibration = prefs.getBool(_vibrationKey) ?? true;
    _keepAwake = prefs.getBool(_keepAwakeKey) ?? true;
    _voice = prefs.getBool(_voiceKey) ?? true;
    _themeMode = _themeFromString(prefs.getString(_themeKey));
    notifyListeners();
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    notifyListeners();
  }

  set soundEnabled(bool v) {
    _sound = v;
    _setBool(_soundKey, v);
  }

  set vibrationEnabled(bool v) {
    _vibration = v;
    _setBool(_vibrationKey, v);
  }

  set keepAwakeEnabled(bool v) {
    _keepAwake = v;
    _setBool(_keepAwakeKey, v);
  }

  set voiceEnabled(bool v) {
    _voice = v;
    _setBool(_voiceKey, v);
  }

  set themeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setString(_themeKey, mode.name));
  }

  static ThemeMode _themeFromString(String? s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
