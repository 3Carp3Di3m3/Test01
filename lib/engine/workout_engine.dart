import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/workout_schedule.dart';

/// Sound/vibration cues the engine emits. The engine only *announces*
/// cues — playing sounds is someone else's job (stage 4).
enum WorkoutCue {
  /// A new interval started (beep + vibrate).
  phaseChange,

  /// One of the last 3 seconds of an interval ticked (short beep).
  countdown,

  /// The whole workout finished (distinct finish sound).
  finish,
}

/// Drives a workout from a monotonic clock.
///
/// Reliability rule: ticks are NEVER counted. A [Stopwatch] (monotonic, not
/// affected by the user changing the system time) measures elapsed time, and
/// on every tick the current phase is *computed* from that elapsed time via
/// [WorkoutSchedule.positionAt]. The periodic [Timer] only refreshes the
/// display — if it fires late or not at all (backgrounded app), the next
/// tick still shows the correct time.
class WorkoutEngine extends ChangeNotifier {
  final WorkoutSchedule schedule;

  /// Called for every cue (interval change, 3-2-1 countdown, finish).
  final void Function(WorkoutCue cue, WorkoutPosition position)? onCue;

  final Stopwatch _stopwatch = Stopwatch();

  /// Offset added to the stopwatch: set by skips and by restoring a
  /// previously saved workout.
  double _skewSeconds = 0;

  Timer? _ticker;
  bool _finished = false;

  // Cue bookkeeping: what we last announced, so each cue fires exactly once.
  int _lastIntervalIndex = -1;
  int _lastCountdownSecond = -1;

  WorkoutEngine(this.schedule, {this.onCue});

  /// Elapsed workout time in seconds (excludes paused time).
  double get elapsed => _skewSeconds + _stopwatch.elapsedMilliseconds / 1000.0;

  WorkoutPosition get position => schedule.positionAt(elapsed);

  bool get isRunning => _stopwatch.isRunning;
  bool get isFinished => _finished;

  double get totalRemaining =>
      (schedule.totalSeconds - elapsed).clamp(0, double.infinity);

  void start() {
    if (_finished) return;
    _stopwatch.start();
    _startTicker();
    _tick(); // fire the first phase-change cue immediately
  }

  void pause() {
    _stopwatch.stop();
    _stopTicker();
    notifyListeners();
  }

  void resume() {
    if (_finished) return;
    _stopwatch.start();
    _startTicker();
    notifyListeners();
  }

  /// Jump to the start of the next interval (or finish if on the last one).
  void skipNext() {
    if (_finished) return;
    _setElapsed(position.interval.endOffsetSeconds.toDouble());
    _tick();
  }

  /// Restart the current interval, or jump to the previous one when we're
  /// within its first second (same behavior as music players).
  void skipPrevious() {
    if (_finished) return;
    final pos = position;
    final intoInterval = elapsed - pos.interval.startOffsetSeconds;
    if (intoInterval > 1.0 || pos.index == 0) {
      _setElapsed(pos.interval.startOffsetSeconds.toDouble());
    } else {
      _setElapsed(
          schedule.intervals[pos.index - 1].startOffsetSeconds.toDouble());
    }
    // Allow the phase-change cue for the interval we jumped into.
    _lastIntervalIndex = -1;
    _tick();
  }

  void stop() {
    _stopwatch.stop();
    _stopTicker();
  }

  /// Restore a previously persisted workout (stage 5): continue as if
  /// [elapsedSeconds] had already passed.
  void restoreElapsed(double elapsedSeconds) {
    _setElapsed(elapsedSeconds);
    _lastIntervalIndex = position.index; // don't re-announce current phase
  }

  void _setElapsed(double seconds) {
    _skewSeconds = seconds - _stopwatch.elapsedMilliseconds / 1000.0;
  }

  void _startTicker() {
    _ticker ??=
        Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  void _tick() {
    final pos = position;

    if (pos.isFinished && !_finished) {
      _finished = true;
      _stopwatch.stop();
      _stopTicker();
      onCue?.call(WorkoutCue.finish, pos);
      notifyListeners();
      return;
    }

    if (pos.index != _lastIntervalIndex) {
      _lastIntervalIndex = pos.index;
      _lastCountdownSecond = -1;
      onCue?.call(WorkoutCue.phaseChange, pos);
    } else {
      final remaining = pos.displayRemaining;
      if (remaining <= 3 &&
          remaining >= 1 &&
          remaining != _lastCountdownSecond) {
        _lastCountdownSecond = remaining;
        onCue?.call(WorkoutCue.countdown, pos);
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
