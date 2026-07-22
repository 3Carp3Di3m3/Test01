import 'timer_config.dart';

/// The kind of interval currently running. Each phase has its own
/// full-screen color on the running timer screen.
enum PhaseType { prepare, work, rest, setRest, done }

/// One concrete interval in the workout, with its absolute position
/// (in seconds from the start of the workout) pre-computed.
class WorkoutInterval {
  final PhaseType phase;

  /// 1-based round number this interval belongs to (0 for prepare/set-rest).
  final int round;

  /// 1-based set number this interval belongs to.
  final int set;

  final int durationSeconds;

  /// Seconds from workout start at which this interval begins.
  final int startOffsetSeconds;

  const WorkoutInterval({
    required this.phase,
    required this.round,
    required this.set,
    required this.durationSeconds,
    required this.startOffsetSeconds,
  });

  int get endOffsetSeconds => startOffsetSeconds + durationSeconds;
}

/// Where we are inside the workout at a given elapsed time.
class WorkoutPosition {
  final WorkoutInterval interval;

  /// Index of [interval] in the schedule's interval list.
  final int index;

  /// Seconds remaining in the current interval (rounded up for display,
  /// use [preciseRemaining] for sub-second accuracy).
  final double preciseRemaining;

  final bool isFinished;

  const WorkoutPosition({
    required this.interval,
    required this.index,
    required this.preciseRemaining,
    this.isFinished = false,
  });

  int get displayRemaining => preciseRemaining.ceil();
}

/// A fully expanded workout: an ordered list of intervals with absolute
/// start offsets. Given any elapsed time it answers "what phase am I in
/// and how long is left" — this is the single source of truth the UI,
/// sounds and notifications all derive from.
class WorkoutSchedule {
  final TimerConfig config;
  final List<WorkoutInterval> intervals;

  WorkoutSchedule._(this.config, this.intervals);

  factory WorkoutSchedule.fromConfig(TimerConfig config) {
    final list = <WorkoutInterval>[];
    var offset = 0;

    void add(PhaseType phase, int round, int set, int duration) {
      if (duration <= 0) return; // zero-length intervals are skipped entirely
      list.add(WorkoutInterval(
        phase: phase,
        round: round,
        set: set,
        durationSeconds: duration,
        startOffsetSeconds: offset,
      ));
      offset += duration;
    }

    add(PhaseType.prepare, 0, 1, config.prepareSeconds);
    for (var set = 1; set <= config.sets; set++) {
      for (var round = 1; round <= config.rounds; round++) {
        add(PhaseType.work, round, set, config.workSeconds);
        // No rest after the final round of a set.
        if (round < config.rounds) {
          add(PhaseType.rest, round, set, config.restSeconds);
        }
      }
      // Set-rest between sets, not after the last one.
      if (set < config.sets) {
        add(PhaseType.setRest, 0, set, config.setRestSeconds);
      }
    }
    return WorkoutSchedule._(config, List.unmodifiable(list));
  }

  int get totalSeconds =>
      intervals.isEmpty ? 0 : intervals.last.endOffsetSeconds;

  /// Compute the current position from elapsed wall-clock time.
  ///
  /// [elapsed] may be fractional seconds. If the workout is over, returns
  /// a position flagged [WorkoutPosition.isFinished] pointing at the last
  /// interval with 0 remaining.
  WorkoutPosition positionAt(double elapsed) {
    assert(intervals.isNotEmpty, 'Schedule must not be empty');
    if (elapsed < 0) elapsed = 0;
    if (elapsed >= totalSeconds) {
      return WorkoutPosition(
        interval: intervals.last,
        index: intervals.length - 1,
        preciseRemaining: 0,
        isFinished: true,
      );
    }
    // Binary search for the interval containing `elapsed`.
    var lo = 0, hi = intervals.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (elapsed >= intervals[mid].endOffsetSeconds) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final interval = intervals[lo];
    return WorkoutPosition(
      interval: interval,
      index: lo,
      preciseRemaining: interval.endOffsetSeconds - elapsed,
    );
  }
}
