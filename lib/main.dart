import 'package:flutter/material.dart';

import 'engine/workout_engine.dart';
import 'models/timer_config.dart';
import 'screens/home_screen.dart';
import 'screens/run_screen.dart';
import 'services/app_settings.dart';
import 'services/cue_player.dart';
import 'services/timer_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = AppSettings()..load();
  runApp(FitTimerApp(
    store: TimerStore()..load(),
    settings: settings,
    cuePlayer: CuePlayer(settings)..init(),
  ));
}

class FitTimerApp extends StatelessWidget {
  final TimerStore store;
  final AppSettings settings;
  final CuePlayer cuePlayer;

  const FitTimerApp({
    super.key,
    required this.store,
    required this.settings,
    required this.cuePlayer,
  });

  void _startWorkout(BuildContext context, TimerConfig config) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RunScreen(
          config: config,
          engineBuilder: (schedule) =>
              WorkoutEngine(schedule, onCue: cuePlayer.handleCue),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const seed = Colors.deepOrange;
    return MaterialApp(
      title: 'FitTimer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(store: store, onStart: _startWorkout),
    );
  }
}
