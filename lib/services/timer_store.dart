import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_config.dart';

/// Loads and saves the list of timers as a JSON string in shared_preferences.
/// Extends [ChangeNotifier] so screens can rebuild when the list changes.
class TimerStore extends ChangeNotifier {
  static const _key = 'timers_v1';

  final List<TimerConfig> _timers = [];
  bool _loaded = false;

  List<TimerConfig> get timers => List.unmodifiable(_timers);
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _timers.clear();
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _timers.addAll(
        list.map((e) => TimerConfig.fromJson(e as Map<String, dynamic>)),
      );
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_timers.map((t) => t.toJson()).toList()),
    );
  }

  /// Insert a new timer or update the one with the same id.
  Future<void> save(TimerConfig config) async {
    final i = _timers.indexWhere((t) => t.id == config.id);
    if (i >= 0) {
      _timers[i] = config;
    } else {
      _timers.add(config);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> delete(String id) async {
    _timers.removeWhere((t) => t.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> toggleFavorite(String id) async {
    final i = _timers.indexWhere((t) => t.id == id);
    if (i < 0) return;
    _timers[i] = _timers[i].copyWith(favorite: !_timers[i].favorite);
    notifyListeners();
    await _persist();
  }

  /// Replace the stored order with [ordered] (e.g. after a drag-reorder).
  Future<void> setOrder(List<TimerConfig> ordered) async {
    _timers
      ..clear()
      ..addAll(ordered);
    notifyListeners();
    await _persist();
  }

  Future<TimerConfig> duplicate(TimerConfig config) async {
    final copy = config.copyWith(id: newId(), name: '${config.name} (copy)');
    _timers.add(copy);
    notifyListeners();
    await _persist();
    return copy;
  }

  /// Unique-enough id for local data: current time in microseconds.
  static String newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
