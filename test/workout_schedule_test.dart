import 'package:flutter_test/flutter_test.dart';
import 'package:fittimer/models/timer_config.dart';
import 'package:fittimer/models/timer_step.dart';
import 'package:fittimer/models/workout_schedule.dart';
import 'package:fittimer/services/timer_share.dart';

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

  group('warm-up and cool-down', () {
    final c = tabata.copyWith(warmupSeconds: 30, cooldownSeconds: 45);

    test('add to total duration', () {
      expect(c.totalSeconds, 30 + 240 + 45);
      expect(WorkoutSchedule.fromConfig(c).totalSeconds, 315);
    });

    test('warm-up is first, then get-ready', () {
      final s = WorkoutSchedule.fromConfig(c);
      expect(s.positionAt(0).interval.phase, PhaseType.warmup);
      expect(s.positionAt(29).interval.phase, PhaseType.warmup);
      // Warm-up 0..30, then prepare 30..40.
      expect(s.positionAt(30).interval.phase, PhaseType.prepare);
      expect(s.positionAt(40).interval.phase, PhaseType.work);
    });

    test('cool-down is the final phase before done', () {
      final s = WorkoutSchedule.fromConfig(c);
      // Whole thing runs 0..315; cool-down is the last 45s (270..315).
      expect(s.positionAt(300).interval.phase, PhaseType.cooldown);
      expect(s.positionAt(314.5).interval.phase, PhaseType.cooldown);
      expect(s.positionAt(315).isFinished, isTrue);
    });

    test('zero warm-up/cool-down are skipped (back-compat)', () {
      final s = WorkoutSchedule.fromConfig(tabata);
      expect(s.intervals.any((i) => i.phase == PhaseType.warmup), isFalse);
      expect(s.intervals.any((i) => i.phase == PhaseType.cooldown), isFalse);
      expect(s.positionAt(0).interval.phase, PhaseType.prepare);
    });
  });

  group('custom step sequences', () {
    const custom = TimerConfig(
      id: 'c',
      name: 'Circuit',
      prepareSeconds: 0,
      rounds: 2,
      steps: [
        TimerStep(name: 'Push-ups', seconds: 30, isRest: false),
        TimerStep(name: 'Break', seconds: 10, isRest: true),
        TimerStep(name: 'Squats', seconds: 20, isRest: false),
      ],
    );

    test('isCustom flips on non-empty steps', () {
      expect(custom.isCustom, isTrue);
      expect(custom.copyWith(steps: const []).isCustom, isFalse);
    });

    test('total = rounds × sum(steps)', () {
      expect(custom.totalSeconds, 2 * (30 + 10 + 20));
    });

    test('schedule expands steps with labels and phases', () {
      final s = WorkoutSchedule.fromConfig(custom);
      expect(s.intervals.length, 6); // 3 steps × 2 rounds
      expect(s.intervals.first.label, 'Push-ups');
      expect(s.intervals.first.phase, PhaseType.work);
      expect(s.intervals[1].phase, PhaseType.rest); // "Break" is a rest step
      expect(s.positionAt(30).interval.label, 'Break');
      expect(s.positionAt(60).interval.label, 'Push-ups'); // round 2
    });
  });

  group('timer share codec', () {
    test('encode → decode round-trips fields with a fresh id', () {
      const c = TimerConfig(
        id: 'orig',
        name: 'Shared',
        workSeconds: 45,
        rounds: 6,
        favorite: true,
      );
      final code = TimerShare.encode(c);
      final back = TimerShare.decode(code)!;
      expect(back.name, 'Shared');
      expect(back.workSeconds, 45);
      expect(back.rounds, 6);
      expect(back.favorite, isTrue);
      expect(back.id, isNot('orig')); // new id on import
    });

    test('garbage returns null', () {
      expect(TimerShare.decode('not a code'), isNull);
      expect(TimerShare.decode('ROUND1:@@@'), isNull);
    });
  });
}
