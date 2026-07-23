import 'package:flutter/material.dart';

import 'engine/workout_engine.dart';
import 'models/timer_config.dart';
import 'models/workout_schedule.dart';
import 'screens/home_screen.dart';
import 'screens/run_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_settings.dart';
import 'services/cue_player.dart';
import 'services/foreground_service.dart';
import 'services/running_session_store.dart';
import 'services/timer_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WorkoutForegroundService.init();
  final settings = AppSettings()..load();
  runApp(FitTimerApp(
    store: TimerStore()..load(),
    settings: settings,
    cuePlayer: CuePlayer(settings)..init(),
    sessionStore: RunningSessionStore(),
  ));
}

class FitTimerApp extends StatelessWidget {
  final TimerStore store;
  final AppSettings settings;
  final CuePlayer cuePlayer;
  final RunningSessionStore sessionStore;

  const FitTimerApp({
    super.key,
    required this.store,
    required this.settings,
    required this.cuePlayer,
    required this.sessionStore,
  });

  @override
  Widget build(BuildContext context) {
    const seed = Colors.deepOrange;
    return MaterialApp(
      title: 'RoundOne',
      theme: _theme(Brightness.light, seed),
      darkTheme: _theme(Brightness.dark, seed),
      themeMode: ThemeMode.system,
      home: AppRoot(
        store: store,
        settings: settings,
        cuePlayer: cuePlayer,
        sessionStore: sessionStore,
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
/// cues → sounds, phase changes → notification text + state saves,
/// exit → cleanup. Also offers to resume an interrupted workout on launch.
class AppRoot extends StatefulWidget {
  final TimerStore store;
  final AppSettings settings;
  final CuePlayer cuePlayer;
  final RunningSessionStore sessionStore;

  const AppRoot({
    super.key,
    required this.store,
    required this.settings,
    required this.cuePlayer,
    required this.sessionStore,
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

  void _startWorkout(
    BuildContext context,
    TimerConfig config, {
    double initialElapsed = 0,
    bool startPaused = false,
  }) {
    WorkoutForegroundService.requestPermissions();

    void onCue(WorkoutCue cue, WorkoutPosition pos) {
      widget.cuePlayer.handleCue(cue, pos);
      if (cue == WorkoutCue.phaseChange) {
        // Elapsed time can be derived from the position itself.
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
      }
    }

    Navigator.push(
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
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(settings: widget.settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      store: widget.store,
      onStart: _startWorkout,
      onOpenSettings: _openSettings,
    );
  }
}
