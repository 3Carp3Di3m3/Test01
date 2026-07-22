import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/timer_config.dart';

/// A workout restored from disk after the app was killed mid-workout.
class RestoredSession {
  final TimerConfig config;
  final bool paused;

  /// Elapsed workout seconds *right now*: if the workout was running when
  /// the state was saved, wall-clock time since the save is added back.
  final double elapsedNow;

  const RestoredSession({
    required this.config,
    required this.paused,
    required this.elapsedNow,
  });
}

/// Persists the state of the currently running workout so it can be
/// resumed at the correct point if the app is killed.
///
/// Because the schedule is computed from elapsed time (not tick counts),
/// resuming only needs: which timer, how many seconds had elapsed, and
/// when we saved — everything else is derived.
class RunningSessionStore {
  static const _key = 'running_session_v1';

  Future<void> save(TimerConfig config, double elapsed,
      {required bool paused}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'config': config.toJson(),
        'elapsed': elapsed,
        'paused': paused,
        'savedAtMs': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Returns the interrupted workout, or null if there is none or it
  /// would already be over by now.
  Future<RestoredSession?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final config =
          TimerConfig.fromJson(data['config'] as Map<String, dynamic>);
      final paused = data['paused'] as bool? ?? false;
      var elapsed = (data['elapsed'] as num).toDouble();
      if (!paused) {
        final savedAt = data['savedAtMs'] as int;
        elapsed +=
            (DateTime.now().millisecondsSinceEpoch - savedAt) / 1000.0;
      }
      if (elapsed >= config.totalSeconds) {
        await clear();
        return null;
      }
      return RestoredSession(
          config: config, paused: paused, elapsedNow: elapsed);
    } catch (_) {
      await clear();
      return null;
    }
  }
}
