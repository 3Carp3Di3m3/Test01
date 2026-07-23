import 'package:flutter/material.dart';

import 'engine/workout_engine.dart';
import 'models/timer_config.dart';
import 'models/workout_record.dart';
import 'models/workout_schedule.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/run_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_settings.dart';
import 'services/cue_player.dart';
import 'services/foreground_service.dart';
import 'services/history_store.dart';
import 'services/running_session_store.dart';
import 'services/timer_store.dart';
import 'services/voice_coach.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WorkoutForegroundService.init();
  final settings = AppSettings()..load();
  runApp(FitTimerApp(
    store: TimerStore()..load(),
    settings: settings,
    cuePlayer: CuePlayer(settings)..init(),
    voiceCoach: VoiceCoach(settings)..init(),
    sessionStore: RunningSessionStore(),
    history: HistoryStore()..load(),
  ));
}

class FitTimerApp extends StatelessWidget {
  final TimerStore store;
  final AppSettings settings;
  final CuePlayer cuePlayer;
  final VoiceCoach voiceCoach;
  final RunningSessionStore sessionStore;
  final HistoryStore history;

  const FitTimerApp({
    super.key,
    required this.store,
    required this.settings,
    required this.cuePlayer,
    required this.voiceCoach,
    required this.sessionStore,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    const seed = Colors.deepOrange;
    // Rebuild when the theme-mode setting changes.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        title: 'RoundOne',
        theme: _theme(Brightness.light, seed),
        darkTheme: _theme(Brightness.dark, seed),
        themeMode: settings.themeMode,
        home: AppRoot(
          store: store,
          settings: settings,
          cuePlayer: cuePlayer,
          voiceCoach: voiceCoach,
          sessionStore: sessionStore,
          history: history,
        ),
      ),
    );
  }

  static ThemeData _theme(Brightness brightness, Color seed) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      cardTheme: CardThemeData(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Hosts the home screen and owns the "start a workout" wiring:
/// cues → sounds + voice, phase changes → notification text + state saves,
/// finish → history logging, exit → cleanup. Also offers to resume an
/// interrupted workout on launch.
class AppRoot extends StatefulWidget {
  final TimerStore store;
  final AppSettings settings;
  final CuePlayer cuePlayer;
  final VoiceCoach voiceCoach;
  final RunningSessionStore sessionStore;
  final HistoryStore history;

  const AppRoot({
    super.key,
    required this.store,
    required this.settings,
    required this.cuePlayer,
    required this.voiceCoach,
    required this.sessionStore,
    required this.history,
  });

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerResume());
  }

  Future<void> _offerResume() async {
    final restored = await widget.sessionStore.load();
    if (restored == null || !mounted) return;
    final resume = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resume workout?'),
        content: Text(
          'A "${restored.config.name}" workout was interrupted. '
          'Continue where you left off?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (resume == true) {
      _startWorkout(
        context,
        restored.config,
        initialElapsed: restored.elapsedNow,
        startPaused: restored.paused,
      );
    } else {
      await widget.sessionStore.clear();
      await WorkoutForegroundService.stop();
    }
  }

  Future<void> _startWorkout(
    BuildContext context,
    TimerConfig config, {
    double initialElapsed = 0,
    bool startPaused = false,
  }) async {
    WorkoutForegroundService.requestPermissions();

    void onCue(WorkoutCue cue, WorkoutPosition pos) {
      widget.cuePlayer.handleCue(cue, pos);
      widget.voiceCoach.handleCue(cue, pos);
      if (cue == WorkoutCue.phaseChange) {
        final elapsed = pos.interval.endOffsetSeconds - pos.preciseRemaining;
        widget.sessionStore.save(config, elapsed, paused: false);
        WorkoutForegroundService.start(
          '${phaseLabel(pos.interval.phase)} — ${config.name}',
          pos.interval.round > 0
              ? 'Round ${pos.interval.round}/${config.rounds}'
                  '${config.sets > 1 ? ' · Set ${pos.interval.set}/${config.sets}' : ''}'
              : 'Workout in progress',
        );
      } else if (cue == WorkoutCue.finish) {
        widget.sessionStore.clear();
        WorkoutForegroundService.stop();
        _logCompletion(config);
      }
    }

    final repeat = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RunScreen(
          config: config,
          initialElapsed: initialElapsed,
          startPaused: startPaused,
          keepAwake: widget.settings.keepAwakeEnabled,
          engineBuilder: (schedule) => WorkoutEngine(schedule, onCue: onCue),
          onLifecycle: (engine, {required bool ended}) {
            if (ended) {
              widget.sessionStore.clear();
              WorkoutForegroundService.stop();
            } else {
              widget.sessionStore
                  .save(config, engine.elapsed, paused: !engine.isRunning);
            }
          },
        ),
      ),
    );

    // "Repeat" on the completion screen re-runs the same workout.
    if (repeat == true && mounted) {
      _startWorkout(this.context, config);
    }
  }

  void _logCompletion(TimerConfig config) {
    widget.history.add(WorkoutRecord(
      timerName: config.name,
      completedAtMs: DateTime.now().millisecondsSinceEpoch,
      durationSeconds: config.totalSeconds,
      totalRounds: config.rounds * config.sets,
    ));
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(settings: widget.settings),
      ),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryScreen(history: widget.history),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      store: widget.store,
      onStart: _startWorkout,
      onOpenSettings: _openSettings,
      onOpenHistory: _openHistory,
    );
  }
}
