import 'package:flutter/material.dart';

import '../models/workout_record.dart';
import '../services/history_store.dart';
import '../utils/format.dart';
import '../widgets/bar_chart.dart';

class HistoryScreen extends StatelessWidget {
  final HistoryStore history;

  /// Injected so the screen is deterministic/testable; defaults to now.
  final DateTime Function() clock;

  const HistoryScreen({
    super.key,
    required this.history,
    DateTime Function()? clock,
  }) : clock = clock ?? DateTime.now;

  Future<void> _confirmClear(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This removes all logged workouts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) await history.clear();
  }

  static List<String> _weekdayLabels(DateTime now, int days) {
    const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S']; // Mon..Sun
    final out = <String>[];
    for (var i = days - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      out.add(names[d.weekday - 1]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          ListenableBuilder(
            listenable: history,
            builder: (context, _) => history.records.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    tooltip: 'Clear history',
                    onPressed: () => _confirmClear(context),
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: history,
        builder: (context, _) {
          if (!history.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = history.records;
          final now = clock();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  _StatTile(
                    label: 'Streak',
                    value: '${history.currentStreak(now)}d',
                    icon: Icons.local_fire_department,
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    label: 'This week',
                    value: '${history.workoutsThisWeek(now)}',
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(width: 12),
                  _StatTile(
                    label: 'Total time',
                    value: formatSeconds(history.totalSeconds),
                    icon: Icons.timelapse,
                  ),
                ],
              ),
              if (history.totalWorkouts > 0) ...[
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Last 7 days',
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 12),
                        MiniBarChart(
                          values: history.lastDaysCounts(now, 7),
                          labels: _weekdayLabels(now, 7),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (records.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Column(
                    children: [
                      Icon(Icons.history,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      const Text('No workouts yet'),
                      const SizedBox(height: 4),
                      Text(
                        'Finish a workout and it shows up here',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ],
                  ),
                )
              else
                for (final r in records) _RecordTile(record: r, now: now),
            ],
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: scheme.primary),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(color: scheme.outline, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final WorkoutRecord record;
  final DateTime now;

  const _RecordTile({required this.record, required this.now});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          child: Icon(Icons.check, color: scheme.onPrimaryContainer),
        ),
        title: Text(record.timerName),
        subtitle: Text(
          '${record.totalRounds} rounds · ${formatSeconds(record.durationSeconds)}',
        ),
        trailing: Text(
          relativeDate(record.completedAt, now),
          style: TextStyle(color: scheme.outline),
        ),
      ),
    );
  }
}
