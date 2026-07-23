import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../engine/workout_engine.dart';
import '../models/step_icons.dart';
import '../models/timer_config.dart';
import '../models/workout_schedule.dart';
import '../utils/format.dart';

/// Full-screen background color per phase. High-saturation shades so the
/// phase is obvious from across the room.
Color phaseColor(PhaseType phase) => switch (phase) {
      PhaseType.warmup => const Color(0xFF00897B), // teal
      PhaseType.prepare => const Color(0xFFF9A825), // yellow
      PhaseType.work => const Color(0xFF2E7D32), // green
      PhaseType.rest => const Color(0xFFC62828), // red
      PhaseType.setRest => const Color(0xFF1565C0), // blue
      PhaseType.cooldown => const Color(0xFF5E35B1), // deep purple
      PhaseType.done => const Color(0xFF6A1B9A), // purple
    };

String phaseLabel(PhaseType phase) => switch (phase) {
      PhaseType.warmup => 'WARM UP',
      PhaseType.prepare => 'GET READY',
      PhaseType.work => 'WORK',
      PhaseType.rest => 'REST',
      PhaseType.setRest => 'SET REST',
      PhaseType.cooldown => 'COOL DOWN',
      PhaseType.done => 'DONE',
    };

/// The running timer. Tap anywhere to pause/resume; buttons for
/// previous / next interval and stop. Works in portrait and landscape:
/// a circular progress ring surrounds huge auto-scaling digits, the whole
/// background eases between phase colors, and a "next up" preview shows
/// what's coming.
class RunScreen extends StatefulWidget {
  final TimerConfig config;

  /// Builds the engine so stage 4/5 can attach sounds and services.
  final WorkoutEngine Function(WorkoutSchedule schedule) engineBuilder;

  /// Called on pause/resume (so state can be persisted) and on exit.
  final void Function(WorkoutEngine engine, {required bool ended})? onLifecycle;

  /// Resume an interrupted workout this many seconds in (0 = fresh start).
  final double initialElapsed;

  /// When restoring a workout that was paused, open the screen paused.
  final bool startPaused;

  /// Keep the screen on while this screen is open (settings toggle).
  final bool keepAwake;

  const RunScreen({
    super.key,
    required this.config,
    required this.engineBuilder,
    this.onLifecycle,
    this.initialElapsed = 0,
    this.startPaused = false,
    this.keepAwake = true,
  });

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  late final WorkoutEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = widget.engineBuilder(WorkoutSchedule.fromConfig(widget.config));
    if (widget.initialElapsed > 0) {
      _engine.restoreElapsed(widget.initialElapsed);
    }
    if (!widget.startPaused) _engine.start();
    if (widget.keepAwake) WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    widget.onLifecycle?.call(_engine, ended: true);
    _engine.dispose();
    super.dispose();
  }

  void _togglePause() {
    if (_engine.isFinished) return;
    _engine.isRunning ? _engine.pause() : _engine.resume();
    widget.onLifecycle?.call(_engine, ended: false);
  }

  Future<void> _confirmStop() async {
    final wasRunning = _engine.isRunning;
    if (wasRunning) _engine.pause();
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop workout?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (leave == true) {
      Navigator.pop(context);
    } else if (wasRunning) {
      _engine.resume();
    }
  }

  /// The phase that comes after the current one, for the "next up" preview.
  WorkoutInterval? _nextInterval(int index) {
    final intervals = _engine.schedule.intervals;
    return index + 1 < intervals.length ? intervals[index + 1] : null;
  }

  /// Full-screen celebration + stats shown when the workout finishes.
  Widget _buildCompletion(BuildContext context) {
    final totalRounds = widget.config.rounds * widget.config.sets;
    final totalTime = _engine.schedule.totalSeconds;
    return Scaffold(
      backgroundColor: phaseColor(PhaseType.done),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events,
                    color: Colors.white, size: 96),
                const SizedBox(height: 16),
                const Text(
                  'Workout complete!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.config.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 20),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CompletionStat(
                      value: formatClock(totalTime),
                      label: 'Total time',
                    ),
                    const SizedBox(width: 40),
                    _CompletionStat(
                      value: '$totalRounds',
                      label: 'Rounds',
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: phaseColor(PhaseType.done),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                  ),
                  icon: const Icon(Icons.replay),
                  label: const Text('Repeat', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Done',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _engine,
      builder: (context, _) {
        if (_engine.isFinished) return _buildCompletion(context);
        final pos = _engine.position;
        final finished = _engine.isFinished;
        final phase = finished ? PhaseType.done : pos.interval.phase;
        final color = phaseColor(phase);
        final interval = pos.interval;
        final progress = finished
            ? 1.0
            : 1.0 - pos.preciseRemaining / interval.durationSeconds;

        final showsRoundInfo = interval.phase == PhaseType.work ||
            interval.phase == PhaseType.rest;
        final roundText = showsRoundInfo
            ? 'Round ${interval.round}/${widget.config.rounds}'
                '${widget.config.sets > 1 ? ' · Set ${interval.set}/${widget.config.sets}' : ''}'
            : '';

        // For custom sequences show the step name (e.g. "PUSH-UPS") and icon.
        final stepLabel = (!finished && interval.label != null &&
                interval.label!.isNotEmpty)
            ? interval.label!.toUpperCase()
            : phaseLabel(phase);
        final stepIconKey = finished ? null : interval.iconKey;

        final next = finished ? null : _nextInterval(pos.index);
        final nextName = next == null
            ? 'Finish'
            : (next.label != null && next.label!.isNotEmpty
                ? next.label!
                : phaseLabel(next.phase));
        final nextText = finished
            ? ''
            : next == null
                ? 'Next: Finish'
                : 'Next: $nextName · ${formatClock(next.durationSeconds)}';

        return Scaffold(
          backgroundColor: Colors.black,
          body: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut,
            color: color,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _togglePause,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    // Phase name, animated on change.
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: ScaleTransition(scale: anim, child: child),
                      ),
                      child: Row(
                        key: ValueKey(stepLabel),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (stepIconKey != null) ...[
                            Icon(stepIcon(stepIconKey),
                                color: Colors.white, size: 30),
                            const SizedBox(width: 10),
                          ],
                          Flexible(
                            child: Text(
                              stepLabel,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (roundText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          roundText,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 22),
                        ),
                      ),
                    // Ring + digits fill the middle.
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _RingWithDigits(
                          progress: progress.clamp(0.0, 1.0),
                          text: finished
                              ? 'DONE'
                              : formatClock(pos.displayRemaining),
                          paused: !finished && !_engine.isRunning,
                        ),
                      ),
                    ),
                    // Total time left / paused hint.
                    if (!finished)
                      Text(
                        _engine.isRunning
                            ? 'Total left: ${formatClock(_engine.totalRemaining.ceil())}'
                            : 'PAUSED — tap to resume',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20),
                      ),
                    // Next-up preview.
                    if (nextText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          nextText,
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 17),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _RoundButton(
                            icon: Icons.skip_previous,
                            onPressed: finished ? null : _engine.skipPrevious,
                          ),
                          _RoundButton(
                            icon: finished
                                ? Icons.check
                                : (_engine.isRunning
                                    ? Icons.pause
                                    : Icons.play_arrow),
                            large: true,
                            onPressed: finished
                                ? () => Navigator.pop(context)
                                : _togglePause,
                          ),
                          _RoundButton(
                            icon: Icons.skip_next,
                            onPressed: finished ? null : _engine.skipNext,
                          ),
                          _RoundButton(
                            icon: Icons.stop,
                            onPressed: finished
                                ? () => Navigator.pop(context)
                                : _confirmStop,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A circular progress ring with big auto-scaling text centered inside.
class _RingWithDigits extends StatelessWidget {
  final double progress;
  final String text;
  final bool paused;

  const _RingWithDigits({
    required this.progress,
    required this.text,
    required this.paused,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final stroke = (side * 0.045).clamp(8.0, 26.0);
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animate the arc smoothly between ticks.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: progress, end: progress),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, value, _) => CustomPaint(
                    size: Size.square(side),
                    painter: _RingPainter(
                      progress: value,
                      stroke: stroke,
                      dim: paused,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(stroke + side * 0.10),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      text,
                      style: TextStyle(
                        color: paused ? Colors.white70 : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 400,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double stroke;
  final bool dim;

  _RingPainter({
    required this.progress,
    required this.stroke,
    required this.dim,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: dim ? 0.55 : 1.0);
    // Start at top (-90°), sweep clockwise by progress.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.stroke != stroke || old.dim != dim;
}

class _CompletionStat extends StatelessWidget {
  final String value;
  final String label;

  const _CompletionStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool large;

  const _RoundButton({required this.icon, this.onPressed, this.large = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: large ? 52 : 38,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white24,
        disabledForegroundColor: Colors.white38,
        padding: EdgeInsets.all(large ? 18 : 12),
      ),
    );
  }
}
