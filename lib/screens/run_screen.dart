import 'package:flutter/material.dart';

import '../engine/workout_engine.dart';
import '../models/timer_config.dart';
import '../models/workout_schedule.dart';
import '../utils/format.dart';

/// Full-screen background color per phase. High-saturation shades so the
/// phase is obvious from across the room.
Color phaseColor(PhaseType phase) => switch (phase) {
      PhaseType.prepare => const Color(0xFFF9A825), // yellow
      PhaseType.work => const Color(0xFF2E7D32), // green
      PhaseType.rest => const Color(0xFFC62828), // red
      PhaseType.setRest => const Color(0xFF1565C0), // blue
      PhaseType.done => const Color(0xFF6A1B9A), // purple
    };

String phaseLabel(PhaseType phase) => switch (phase) {
      PhaseType.prepare => 'GET READY',
      PhaseType.work => 'WORK',
      PhaseType.rest => 'REST',
      PhaseType.setRest => 'SET REST',
      PhaseType.done => 'DONE',
    };

/// The running timer. Tap anywhere to pause/resume; buttons for
/// previous / next interval and stop. Works in portrait and landscape:
/// the digits scale with FittedBox, so they always fill the space.
class RunScreen extends StatefulWidget {
  final TimerConfig config;

  /// Builds the engine so stage 4/5 can attach sounds and services.
  final WorkoutEngine Function(WorkoutSchedule schedule) engineBuilder;

  /// Called whenever engine state should be persisted, and on exit
  /// (stage 5). Null until then.
  final void Function(WorkoutEngine engine, {required bool ended})? onLifecycle;

  const RunScreen({
    super.key,
    required this.config,
    required this.engineBuilder,
    this.onLifecycle,
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
    _engine.start();
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _engine,
      builder: (context, _) {
        final pos = _engine.position;
        final finished = _engine.isFinished;
        final phase = finished ? PhaseType.done : pos.interval.phase;
        final color = phaseColor(phase);
        final interval = pos.interval;
        final progress = finished
            ? 1.0
            : 1.0 - pos.preciseRemaining / interval.durationSeconds;

        final roundText = interval.phase == PhaseType.work ||
                interval.phase == PhaseType.rest
            ? 'Round ${interval.round}/${widget.config.rounds}'
                '${widget.config.sets > 1 ? ' · Set ${interval.set}/${widget.config.sets}' : ''}'
            : (widget.config.sets > 1 && interval.phase == PhaseType.setRest
                ? 'Set ${interval.set} done'
                : '');

        return Scaffold(
          backgroundColor: color,
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _togglePause,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    phaseLabel(phase),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  if (roundText.isNotEmpty)
                    Text(
                      roundText,
                      style: const TextStyle(color: Colors.white70, fontSize: 22),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Text(
                          finished
                              ? 'DONE'
                              : formatClock(pos.displayRemaining),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 400,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!finished) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _engine.isRunning
                          ? 'Total left: ${formatClock(_engine.totalRemaining.ceil())}'
                          : 'PAUSED — tap to resume',
                      style: const TextStyle(color: Colors.white70, fontSize: 20),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(12),
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
                          onPressed:
                              finished ? () => Navigator.pop(context) : _togglePause,
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
        );
      },
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
      iconSize: large ? 56 : 40,
      style: IconButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white24,
        disabledForegroundColor: Colors.white38,
      ),
    );
  }
}
