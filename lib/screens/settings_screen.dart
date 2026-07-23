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
            const _SectionHeader('Sound & feedback'),
            SwitchListTile(
              title: const Text('Sound'),
              subtitle: const Text('Beeps at interval changes and countdown'),
              secondary: const Icon(Icons.volume_up_outlined),
              value: settings.soundEnabled,
              onChanged: (v) => settings.soundEnabled = v,
            ),
            SwitchListTile(
              title: const Text('Voice coach'),
              subtitle:
                  const Text('Spoken cues: “Work”, “Rest”, round numbers'),
              secondary: const Icon(Icons.record_voice_over_outlined),
              value: settings.voiceEnabled,
              onChanged: (v) => settings.voiceEnabled = v,
            ),
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Vibrate together with the beeps'),
              secondary: const Icon(Icons.vibration),
              value: settings.vibrationEnabled,
              onChanged: (v) => settings.vibrationEnabled = v,
            ),
            const Divider(),
            const _SectionHeader('Workout'),
            SwitchListTile(
              title: const Text('Keep screen awake'),
              subtitle: const Text('Screen stays on during a workout'),
              secondary: const Icon(Icons.brightness_high_outlined),
              value: settings.keepAwakeEnabled,
              onChanged: (v) => settings.keepAwakeEnabled = v,
            ),
            const Divider(),
            const _SectionHeader('Goals'),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Weekly goal'),
              subtitle: Text('${settings.weeklyGoal} workouts per week'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: settings.weeklyGoal > 1
                        ? () => settings.weeklyGoal = settings.weeklyGoal - 1
                        : null,
                  ),
                  Text('${settings.weeklyGoal}',
                      style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () =>
                        settings.weeklyGoal = settings.weeklyGoal + 1,
                  ),
                ],
              ),
            ),
            const Divider(),
            const _SectionHeader('Appearance'),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Theme'),
              subtitle: Text(_themeLabel(settings.themeMode)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('System'),
                    icon: Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Light'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Dark'),
                    icon: Icon(Icons.dark_mode),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => settings.themeMode = s.first,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'Follow system',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
