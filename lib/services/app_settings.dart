import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide toggles, persisted in shared_preferences.
class AppSettings extends ChangeNotifier {
  static const _soundKey = 'settings_sound';
  static const _vibrationKey = 'settings_vibration';
  static const _keepAwakeKey = 'settings_keep_awake';
  static const _voiceKey = 'settings_voice';
  static const _themeKey = 'settings_theme_mode';
  static const _weeklyGoalKey = 'settings_weekly_goal';
  static const _accentKey = 'settings_accent';
  static const _soundPackKey = 'settings_sound_pack';
  static const _onboardedKey = 'settings_onboarded';

  /// Selectable accent colors (seed for the whole theme).
  static const accentChoices = <int>[
    0xFFFF5722, // deep orange (default)
    0xFF2E7D32, // green
    0xFF1565C0, // blue
    0xFF6A1B9A, // purple
    0xFFC62828, // red
    0xFF00897B, // teal
    0xFFF9A825, // amber
    0xFFEC407A, // pink
  ];

  /// Available beep sound packs (folder under assets/sounds; '' = classic).
  static const soundPacks = <String>['classic', 'soft', 'digital'];

  bool _sound = true;
  bool _vibration = true;
  bool _keepAwake = true;
  bool _voice = true;
  ThemeMode _themeMode = ThemeMode.system;
  int _weeklyGoal = 4;
  int _accent = 0xFFFF5722;
  String _soundPack = 'classic';
  bool _onboarded = false;

  bool get soundEnabled => _sound;
  bool get vibrationEnabled => _vibration;
  bool get keepAwakeEnabled => _keepAwake;
  bool get voiceEnabled => _voice;
  ThemeMode get themeMode => _themeMode;
  int get weeklyGoal => _weeklyGoal;
  int get accentColor => _accent;
  String get soundPack => _soundPack;
  bool get onboarded => _onboarded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _sound = prefs.getBool(_soundKey) ?? true;
    _vibration = prefs.getBool(_vibrationKey) ?? true;
    _keepAwake = prefs.getBool(_keepAwakeKey) ?? true;
    _voice = prefs.getBool(_voiceKey) ?? true;
    _themeMode = _themeFromString(prefs.getString(_themeKey));
    _weeklyGoal = prefs.getInt(_weeklyGoalKey) ?? 4;
    _accent = prefs.getInt(_accentKey) ?? 0xFFFF5722;
    _soundPack = prefs.getString(_soundPackKey) ?? 'classic';
    _onboarded = prefs.getBool(_onboardedKey) ?? false;
    notifyListeners();
  }

  set onboarded(bool v) {
    _onboarded = v;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setBool(_onboardedKey, v));
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

  set weeklyGoal(int goal) {
    _weeklyGoal = goal.clamp(1, 21);
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setInt(_weeklyGoalKey, _weeklyGoal));
  }

  set accentColor(int value) {
    _accent = value;
    notifyListeners();
    SharedPreferences.getInstance().then((p) => p.setInt(_accentKey, value));
  }

  set soundPack(String pack) {
    _soundPack = pack;
    notifyListeners();
    SharedPreferences.getInstance()
        .then((p) => p.setString(_soundPackKey, pack));
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
