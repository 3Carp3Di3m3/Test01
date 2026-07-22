import 'package:flutter/material.dart';

import '../models/timer_config.dart';
import '../services/timer_store.dart';
import '../utils/format.dart';
import '../widgets/stepper_row.dart';

/// Create or edit a timer: name, steppers for all values, preset chips,
/// and a live total-duration readout.
class EditTimerScreen extends StatefulWidget {
  final TimerStore store;

  /// Timer to edit, or null to create a new one.
  final TimerConfig? existing;

  const EditTimerScreen({super.key, required this.store, this.existing});

  @override
  State<EditTimerScreen> createState() => _EditTimerScreenState();
}

class _EditTimerScreenState extends State<EditTimerScreen> {
  late TimerConfig _config;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _config = widget.existing ??
        TimerConfig.preset('custom', TimerStore.newId()).copyWith(name: 'My timer');
    _nameController = TextEditingController(text: _config.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyPreset(String kind) {
    setState(() {
      // Keep the same id so applying a preset while editing overwrites
      // values but still saves back to the same timer.
      _config = TimerConfig.preset(kind, _config.id);
      _nameController.text = _config.name;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    await widget.store
        .save(_config.copyWith(name: name.isEmpty ? 'Unnamed' : name));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New timer' : 'Edit timer'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final kind in const ['tabata', 'hiit', 'boxing', 'custom'])
                ActionChip(
                  label: Text(kind[0].toUpperCase() + kind.substring(1)),
                  onPressed: () => _applyPreset(kind),
                ),
            ],
          ),
          const Divider(height: 24),
          StepperRow(
            label: 'Get ready',
            value: _config.prepareSeconds,
            step: 5,
            format: formatSeconds,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(prepareSeconds: v)),
          ),
          StepperRow(
            label: 'Work',
            value: _config.workSeconds,
            step: 5,
            min: 5,
            format: formatSeconds,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(workSeconds: v)),
          ),
          StepperRow(
            label: 'Rest',
            value: _config.restSeconds,
            step: 5,
            format: formatSeconds,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(restSeconds: v)),
          ),
          StepperRow(
            label: 'Rounds',
            value: _config.rounds,
            min: 1,
            max: 99,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(rounds: v)),
          ),
          StepperRow(
            label: 'Sets',
            value: _config.sets,
            min: 1,
            max: 20,
            onChanged: (v) => setState(() => _config = _config.copyWith(sets: v)),
          ),
          StepperRow(
            label: 'Rest between sets',
            value: _config.setRestSeconds,
            step: 5,
            format: formatSeconds,
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(setRestSeconds: v)),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Total: ${formatSeconds(_config.totalSeconds)}',
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
