import 'dart:convert';

import '../models/timer_config.dart';
import 'timer_store.dart';

/// Encodes/decodes a timer to a shareable text code so users can copy a
/// timer and paste it on another device. Format: "ROUND1:" + base64(JSON).
class TimerShare {
  static const _prefix = 'ROUND1:';

  static String encode(TimerConfig config) {
    final json = jsonEncode(config.toJson());
    return _prefix + base64Url.encode(utf8.encode(json));
  }

  /// Decodes a code into a timer with a fresh id, or returns null if the
  /// code is not a valid RoundOne timer.
  static TimerConfig? decode(String code) {
    final trimmed = code.trim();
    if (!trimmed.startsWith(_prefix)) return null;
    try {
      final payload = trimmed.substring(_prefix.length);
      final json = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(json) as Map<String, dynamic>;
      final config = TimerConfig.fromJson(map);
      // Give it a new id so importing never collides with an existing timer.
      return config.copyWith(id: TimerStore.newId());
    } catch (_) {
      return null;
    }
  }
}
