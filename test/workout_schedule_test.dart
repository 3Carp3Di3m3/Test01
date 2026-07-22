import 'package:flutter_test/flutter_test.dart';
import 'package:fittimer/models/timer_config.dart';
import 'package:fittimer/models/workout_schedule.dart';

void main() {
  // Tabata: 10s prepare + 8 × 20s work with 10s rest between rounds
  // = 10 + 8*20 + 7*10 = 240 seconds.
  const tabata = TimerConfig(
    id: 't',
    name: 'Tabata',
    prepareSeconds: 10,
    workSeconds: 20,
    restSeconds: 10,
    rounds: 8,
    sets: 1,
    setRestSeconds: 60,
  );

  group('total duration', () {
    test('tabata is 4 minutes', () {
      expect(tabata.totalSeconds, 240);
      expect(WorkoutSchedule.fromConfig(tabata).totalSeconds, 240);
    });

    test('multiple sets add set-rest between sets only', () {
      final two = tabata.copyWith(sets: 2, setRestSeconds: 60);
      // one set without prepare = 8*20 + 7*10 = 230
      expect(two.totalSeconds, 10 + 230 + 60 + 230);
      expect(WorkoutSchedule.fromConfig(two).totalSeconds, two.totalSeconds);
    });

    test('zero prepare and zero rest are skipped', () {
      final c = tabata.copyWith(prepareSeconds: 0, restSeconds: 0);
      expect(c.totalSeconds, 160);
      final s = WorkoutSchedule.fromConfig(c);
      expect(s.totalSeconds, 160);
      expect(s.intervals.every((i) => i.phase == PhaseType.work), isTrue);
      expect(s.intervals.length, 8);
    });

    test('single round has no rest at all', () {
      final c = tabata.copyWith(rounds: 1);
      expect(c.totalSeconds, 30);
      expect(WorkoutSchedule.fromConfig(c).intervals.length, 2);
    });
  });

  group('positionAt (what phase am I in at second X)', () {
    final s = WorkoutSchedule.fromConfig(tabata);

    test('second 0 is prepare', () {
      final p = s.positionAt(0);
      expect(p.interval.phase, PhaseType.prepare);
      expect(p.displayRemaining, 10);
      expect(p.isFinished, isFalse);
    });

    test('second 10 is start of work round 1', () {
      final p = s.positionAt(10);
      expect(p.interval.phase, PhaseType.work);
      expect(p.interval.round, 1);
      expect(p.displayRemaining, 20);
    });

    test('second 30 is rest after round 1', () {
      final p = s.positionAt(30);
      expect(p.interval.phase, PhaseType.rest);
      expect(p.interval.round, 1);
    });

    test('fractional elapsed rounds remaining up for display', () {
      final p = s.positionAt(10.5);
      expect(p.interval.phase, PhaseType.work);
      expect(p.preciseRemaining, closeTo(19.5, 1e-9));
      expect(p.displayRemaining, 20);
    });

    test('last second of workout is work round 8', () {
      final p = s.positionAt(239.9);
      expect(p.interval.phase, PhaseType.work);
      expect(p.interval.round, 8);
      expect(p.isFinished, isFalse);
    });

    test('past the end reports finished', () {
      final p = s.positionAt(240);
      expect(p.isFinished, isTrue);
      expect(p.displayRemaining, 0);
      expect(s.positionAt(9999).isFinished, isTrue);
    });

    test('set-rest appears between sets', () {
      final two = WorkoutSchedule.fromConfig(tabata.copyWith(sets: 2));
      // First set ends at 10 + 230 = 240; set-rest runs 240..300.
      final p = two.positionAt(250);
      expect(p.interval.phase, PhaseType.setRest);
      final q = two.positionAt(300);
      expect(q.interval.phase, PhaseType.work);
      expect(q.interval.set, 2);
      expect(q.interval.round, 1);
    });

    test('negative elapsed clamps to start', () {
      expect(s.positionAt(-5).interval.phase, PhaseType.prepare);
    });
  });
}
