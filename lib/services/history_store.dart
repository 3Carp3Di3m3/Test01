import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/workout_record.dart';

/// Persists completed workouts (most recent first) in shared_preferences.
class HistoryStore extends ChangeNotifier {
  static const _key = 'history_v1';
  static const _maxEntries = 500;

  final List<WorkoutRecord> _records = [];
  bool _loaded = false;

  List<WorkoutRecord> get records => List.unmodifiable(_records);
  bool get isLoaded => _loaded;

  int get totalWorkouts => _records.length;

  int get totalSeconds =>
      _records.fold(0, (sum, r) => sum + r.durationSeconds);

  /// Workouts completed within the last 7 days.
  int workoutsThisWeek(DateTime now) {
    final cutoff = now.subtract(const Duration(days: 7));
    return _records.where((r) => r.completedAt.isAfter(cutoff)).length;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    _records.clear();
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      _records.addAll(
        list.map((e) => WorkoutRecord.fromJson(e as Map<String, dynamic>)),
      );
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(WorkoutRecord record) async {
    _records.insert(0, record);
    if (_records.length > _maxEntries) {
      _records.removeRange(_maxEntries, _records.length);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _records.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_records.map((r) => r.toJson()).toList()),
    );
  }
}
