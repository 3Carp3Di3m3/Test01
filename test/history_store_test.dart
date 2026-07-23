import 'package:flutter_test/flutter_test.dart';
import 'package:fittimer/models/workout_record.dart';
import 'package:fittimer/services/history_store.dart';

WorkoutRecord _rec(DateTime when) => WorkoutRecord(
      timerName: 'T',
      completedAtMs: when.millisecondsSinceEpoch,
      durationSeconds: 100,
      totalRounds: 8,
    );

void main() {
  final now = DateTime(2026, 7, 23, 12);

  group('currentStreak', () {
    test('no records is zero', () {
      final s = HistoryStore()..seedForTest([]);
      expect(s.currentStreak(now), 0);
    });

    test('today only is 1', () {
      final s = HistoryStore()..seedForTest([_rec(DateTime(2026, 7, 23, 8))]);
      expect(s.currentStreak(now), 1);
    });

    test('three consecutive days ending today is 3', () {
      final s = HistoryStore()
        ..seedForTest([
          _rec(DateTime(2026, 7, 23, 8)),
          _rec(DateTime(2026, 7, 22, 8)),
          _rec(DateTime(2026, 7, 21, 8)),
        ]);
      expect(s.currentStreak(now), 3);
    });

    test('gap breaks the streak', () {
      final s = HistoryStore()
        ..seedForTest([
          _rec(DateTime(2026, 7, 23, 8)),
          _rec(DateTime(2026, 7, 21, 8)), // missed the 22nd
        ]);
      expect(s.currentStreak(now), 1);
    });

    test('streak stays alive from yesterday if nothing today yet', () {
      final s = HistoryStore()
        ..seedForTest([
          _rec(DateTime(2026, 7, 22, 8)),
          _rec(DateTime(2026, 7, 21, 8)),
        ]);
      expect(s.currentStreak(now), 2);
    });

    test('two workouts same day count as one day', () {
      final s = HistoryStore()
        ..seedForTest([
          _rec(DateTime(2026, 7, 23, 8)),
          _rec(DateTime(2026, 7, 23, 18)),
        ]);
      expect(s.currentStreak(now), 1);
    });
  });

  group('lastDaysCounts', () {
    test('buckets by day, oldest first', () {
      final s = HistoryStore()
        ..seedForTest([
          _rec(DateTime(2026, 7, 23, 8)),
          _rec(DateTime(2026, 7, 23, 9)),
          _rec(DateTime(2026, 7, 21, 8)),
        ]);
      final counts = s.lastDaysCounts(now, 7);
      expect(counts.length, 7);
      expect(counts.last, 2); // today
      expect(counts[4], 1); // two days ago (21st)
      expect(counts.reduce((a, b) => a + b), 3);
    });
  });
}
