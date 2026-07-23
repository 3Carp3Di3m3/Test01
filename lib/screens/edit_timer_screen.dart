import 'package:flutter/material.dart';

import '../models/timer_config.dart';
import '../services/timer_store.dart';
import '../utils/format.dart';
import '../widgets/stepper_row.dart';

/// Create or edit a timer: name, steppers for all values grouped into
/// sections, preset chips, and a live total-duration readout pinned to the
/// bottom.
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
        TimerConfig.preset('custom', TimerStore.newId())
            .copyWith(name: 'My timer');
    _nameController = TextEditingController(text: _config.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _applyPreset(String kind) {
    setState(() {
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

  void _set(TimerConfig next) => setState(() => _config = next);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New timer' : 'Edit timer'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.label_outline),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Text('Presets', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final kind in const ['tabata', 'hiit', 'boxing', 'custom'])
                ActionChip(
                  avatar: const Icon(Icons.flash_on, size: 18),
                  label: Text(kind[0].toUpperCase() + kind.substring(1)),
                  onPressed: () => _applyPreset(kind),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Warm-up',
            icon: Icons.self_improvement,
            color: const Color(0xFF00897B),
            children: [
              StepperRow(
                label: 'Warm-up',
                value: _config.warmupSeconds,
                step: 15,
                format: formatSeconds,
                onChanged: (v) => _set(_config.copyWith(warmupSeconds: v)),
              ),
            ],
          ),
          _Section(
            title: 'Intervals',
            icon: Icons.repeat,
            color: const Color(0xFF2E7D32),
            children: [
              StepperRow(
                label: 'Get ready',
                value: _config.prepareSeconds,
                step: 5,
                format: formatSeconds,
                onChanged: (v) => _set(_config.copyWith(prepareSeconds: v)),
              ),
              StepperRow(
                label: 'Work',
                value: _config.workSeconds,
                step: 5,
                min: 5,
                format: formatSeconds,
                onChanged: (v) => _set(_config.copyWith(workSeconds: v)),
              ),
              StepperRow(
                label: 'Rest',
                value: _config.restSeconds,
                step: 5,
                format: formatSeconds,
                onChanged: (v) => _set(_config.copyWith(restSeconds: v)),
              ),
              StepperRow(
                label: 'Rounds',
                value: _config.rounds,
                min: 1,
                max: 99,
                onChanged: (v) => _set(_config.copyWith(rounds: v)),
              ),
            ],
          ),
          _Section(
            title: 'Sets',
            icon: Icons.layers_outlined,
            color: const Color(0xFF1565C0),
            children: [
              StepperRow(
                label: 'Sets',
                value: _config.sets,
                min: 1,
                max: 20,
                onChanged: (v) => _set(_config.copyWith(sets: v)),
              ),
              StepperRow(
                label: 'Rest between sets',
                value: _config.setRestSeconds,
                step: 5,
                format: formatSeconds,
                onChanged: (v) => _set(_config.copyWith(setRestSeconds: v)),
              ),
            ],
          ),
          _Section(
            title: 'Cool-down',
            icon: Icons.ac_unit,
            color: const Color(0xFF5E35B1),
            children: [
              StepperRow(
                label: 'Cool-down',
                value: _config.cooldownSeconds,
                step: 15,
                format: formatSeconds,
                onChanged: (v) => _set(_config.copyWith(cooldownSeconds: v)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: scheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timelapse, color: scheme.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    'Total ${formatSeconds(_config.totalSeconds)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Save timer'),
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled group of stepper rows with a colored accent header.
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(letterSpacing: 0.5),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...children,
          ],
        ),
      ),
    );
  }
}
