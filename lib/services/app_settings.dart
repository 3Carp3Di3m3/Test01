import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide toggles, persisted in shared_preferences.
class AppSettings extends ChangeNotifier {
  static const _soundKey = 'settings_sound';
  static const _vibrationKey = 'settings_vibration';
  static const _keepAwakeKey = 'settings_keep_awake';

  bool _sound = true;
  bool _vibration = true;
  bool _keepAwake = true;

  bool get soundEnabled => _sound;
  bool get vibrationEnabled => _vibration;
  bool get keepAwakeEnabled => _keepAwake;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _sound = prefs.getBool(_soundKey) ?? true;
    _vibration = prefs.getBool(_vibrationKey) ?? true;
    _keepAwake = prefs.getBool(_keepAwakeKey) ?? true;
    notifyListeners();
  }

  Future<void> _set(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    notifyListeners();
  }

  set soundEnabled(bool v) {
    _sound = v;
    _set(_soundKey, v);
  }

  set vibrationEnabled(bool v) {
    _vibration = v;
    _set(_vibrationKey, v);
  }

  set keepAwakeEnabled(bool v) {
    _keepAwake = v;
    _set(_keepAwakeKey, v);
  }
}
