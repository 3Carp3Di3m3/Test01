import 'package:flutter/material.dart';

import '../models/step_icons.dart';
import '../models/timer_config.dart';
import '../models/timer_step.dart';
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

  void _setMode(bool custom) {
    setState(() {
      if (custom && _config.steps.isEmpty) {
        _config = _config.copyWith(steps: const [
          TimerStep(
              name: 'Exercise 1',
              iconKey: 'dumbbell',
              seconds: 30,
              isRest: false),
          TimerStep(name: 'Rest', iconKey: 'rest', seconds: 15, isRest: true),
        ]);
      } else if (!custom) {
        _config = _config.copyWith(steps: const []);
      }
    });
  }

  void _moveStep(int i, int delta) {
    final steps = [..._config.steps];
    final j = i + delta;
    if (j < 0 || j >= steps.length) return;
    final tmp = steps[i];
    steps[i] = steps[j];
    steps[j] = tmp;
    _set(_config.copyWith(steps: steps));
  }

  void _deleteStep(int i) {
    final steps = [..._config.steps]..removeAt(i);
    _set(_config.copyWith(steps: steps));
  }

  Future<void> _editStep(int? index) async {
    final existing = index != null ? _config.steps[index] : null;
    final result = await showDialog<TimerStep>(
      context: context,
      builder: (_) => _StepEditorDialog(step: existing),
    );
    if (result == null) return;
    final steps = [..._config.steps];
    if (index != null) {
      steps[index] = result;
    } else {
      steps.add(result);
    }
    _set(_config.copyWith(steps: steps));
  }

  Widget _buildStepsSections(BuildContext context) {
    return Column(
      children: [
        _Section(
          title: 'Steps',
          icon: Icons.list_alt,
          color: const Color(0xFF2E7D32),
          children: [
            for (var i = 0; i < _config.steps.length; i++)
              _StepTile(
                step: _config.steps[i],
                canMoveUp: i > 0,
                canMoveDown: i < _config.steps.length - 1,
                onTap: () => _editStep(i),
                onUp: () => _moveStep(i, -1),
                onDown: () => _moveStep(i, 1),
                onDelete: () => _deleteStep(i),
              ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _editStep(null),
                icon: const Icon(Icons.add),
                label: const Text('Add step'),
              ),
            ),
          ],
        ),
        _Section(
          title: 'Repeat',
          icon: Icons.repeat,
          color: const Color(0xFF2E7D32),
          children: [
            StepperRow(
              label: 'Rounds',
              leadingIcon: Icons.repeat,
              iconColor: const Color(0xFF2E7D32),
              value: _config.rounds,
              min: 1,
              max: 99,
              onChanged: (v) => _set(_config.copyWith(rounds: v)),
            ),
          ],
        ),
      ],
    );
  }

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
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest,
            margin: const EdgeInsets.only(bottom: 12),
            child: SwitchListTile(
              secondary: Icon(
                  _config.muted ? Icons.volume_off : Icons.volume_up),
              title: const Text('Mute this timer'),
              subtitle: const Text('No beeps or voice (vibration still works)'),
              value: _config.muted,
              onChanged: (v) => _set(_config.copyWith(muted: v)),
            ),
          ),
          Center(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false,
                    label: Text('Simple'),
                    icon: Icon(Icons.tune)),
                ButtonSegment(
                    value: true,
                    label: Text('Custom'),
                    icon: Icon(Icons.list_alt)),
              ],
              selected: {_config.isCustom},
              onSelectionChanged: (s) => _setMode(s.first),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Warm-up',
            icon: Icons.self_improvement,
            color: const Color(0xFF00897B),
            children: [
              StepperRow(
                label: 'Warm-up',
                leadingIcon: Icons.self_improvement,
                iconColor: const Color(0xFF00897B),
                value: _config.warmupSeconds,
                step: 15,
                format: formatSeconds,
                onChanged: (v) => _set(_config.copyWith(warmupSeconds: v)),
              ),
            ],
          ),
          if (_config.isCustom) _buildStepsSections(context),
          if (!_config.isCustom)
            _Section(
            title: 'Intervals',
            icon: Icons.repeat,
            color: const Color(0xFF2E7D32),
            children: [
              StepperRow(
                label: 'Get ready',
                leadingIcon: Icons.hourglass_top,
                iconColor: const Color(0xFFF9A825),
                value: _config.prepareSeconds,
                step: 5,
                format: formatSeconds,
                onChanged: (v) => _set(_config.copyWith(prepareSeconds: v)),
              ),
              StepperRow(
                label: 'Work',
                leadingIcon: Icons.fitness_center,
                iconColor: const Color(0xFF2E7D32),
                value: _config.workSeconds,
                step: 5,
                min: 5,
                format: formatSeconds,
                onChanged: (v) => _set(_config.copyWith(workSeconds: v)),
              ),
              StepperRow(
                label: 'Rest',
                leadingIcon: Icons.pause_circle_outline,
                iconColor: const Color(0xFFC62828),
                value: _config.restSeconds,
                step: 5,
                format: formatSeconds,
                onChanged: (v) => _set(_config.copyWith(restSeconds: v)),
              ),
              StepperRow(
                label: 'Rounds',
                leadingIcon: Icons.repeat,
                iconColor: const Color(0xFF2E7D32),
                value: _config.rounds,
                min: 1,
                max: 99,
                onChanged: (v) => _set(_config.copyWith(rounds: v)),
              ),
            ],
          ),
          if (!_config.isCustom)
            _Section(
            title: 'Sets',
            icon: Icons.layers_outlined,
            color: const Color(0xFF1565C0),
            children: [
              StepperRow(
                label: 'Sets',
                leadingIcon: Icons.layers_outlined,
                iconColor: const Color(0xFF1565C0),
                value: _config.sets,
                min: 1,
                max: 20,
                onChanged: (v) => _set(_config.copyWith(sets: v)),
              ),
              StepperRow(
                label: 'Rest between sets',
                leadingIcon: Icons.hotel,
                iconColor: const Color(0xFF1565C0),
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
                leadingIcon: Icons.ac_unit,
                iconColor: const Color(0xFF5E35B1),
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

/// One row in the custom-steps editor.
class _StepTile extends StatelessWidget {
  final TimerStep step;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onTap;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onDelete;

  const _StepTile({
    required this.step,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onTap,
    required this.onUp,
    required this.onDown,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = step.isRest ? const Color(0xFFC62828) : const Color(0xFF2E7D32);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Icon(stepIcon(step.iconKey), color: color),
      ),
      title: Text(step.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
          '${formatSeconds(step.seconds)} · ${step.isRest ? 'Rest' : 'Work'}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CompactIcon(
              icon: Icons.arrow_upward, onPressed: canMoveUp ? onUp : null),
          _CompactIcon(
              icon: Icons.arrow_downward,
              onPressed: canMoveDown ? onDown : null),
          _CompactIcon(icon: Icons.delete_outline, onPressed: onDelete),
        ],
      ),
    );
  }
}

class _CompactIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _CompactIcon({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    );
  }
}

/// Dialog to create or edit a single custom step.
class _StepEditorDialog extends StatefulWidget {
  final TimerStep? step;
  const _StepEditorDialog({this.step});

  @override
  State<_StepEditorDialog> createState() => _StepEditorDialogState();
}

class _StepEditorDialogState extends State<_StepEditorDialog> {
  late final TextEditingController _name;
  late String _iconKey;
  late int _seconds;
  late bool _isRest;

  @override
  void initState() {
    super.initState();
    final s = widget.step;
    _name = TextEditingController(text: s?.name ?? '');
    _iconKey = s?.iconKey ?? 'dumbbell';
    _seconds = s?.seconds ?? 30;
    _isRest = s?.isRest ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    Navigator.pop(
      context,
      TimerStep(
        name: name.isEmpty ? (_isRest ? 'Rest' : 'Exercise') : name,
        iconKey: _iconKey,
        seconds: _seconds,
        isRest: _isRest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.step == null ? 'Add step' : 'Edit step'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Push-ups',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Icon'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in kStepIcons.entries)
                  GestureDetector(
                    onTap: () => setState(() => _iconKey = entry.key),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: _iconKey == entry.key
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      child: Icon(
                        entry.value,
                        color: _iconKey == entry.key
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            StepperRow(
              label: 'Duration',
              value: _seconds,
              step: 5,
              min: 5,
              format: formatSeconds,
              onChanged: (v) => setState(() => _seconds = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('This is a rest step'),
              value: _isRest,
              onChanged: (v) => setState(() => _isRest = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
