import 'package:flutter/material.dart';

import '../services/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  final AppSettings settings;

  const SettingsScreen({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          children: [
            SwitchListTile(
              title: const Text('Sound'),
              subtitle: const Text('Beeps at interval changes and countdown'),
              secondary: const Icon(Icons.volume_up_outlined),
              value: settings.soundEnabled,
              onChanged: (v) => settings.soundEnabled = v,
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate together with the beeps'),
              secondary: const Icon(Icons.vibration),
              value: settings.vibrationEnabled,
              onChanged: (v) => settings.vibrationEnabled = v,
            ),
            SwitchListTile(
              title: const Text('Keep screen awake'),
              subtitle: const Text('Screen stays on during a workout'),
              secondary: const Icon(Icons.brightness_high_outlined),
              value: settings.keepAwakeEnabled,
              onChanged: (v) => settings.keepAwakeEnabled = v,
            ),
          ],
        ),
      ),
    );
  }
}
