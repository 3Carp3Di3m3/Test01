import 'package:flutter/material.dart';

import 'models/timer_config.dart';
import 'screens/home_screen.dart';
import 'services/timer_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(FitTimerApp(store: TimerStore()..load()));
}

class FitTimerApp extends StatelessWidget {
  final TimerStore store;

  const FitTimerApp({super.key, required this.store});

  void _startWorkout(BuildContext context, TimerConfig config) {
    // Running timer screen arrives in stage 3.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Running "${config.name}" — coming in stage 3')),
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
