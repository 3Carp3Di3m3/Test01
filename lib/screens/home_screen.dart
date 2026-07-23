import 'package:flutter/material.dart';

import '../models/timer_config.dart';
import '../services/timer_store.dart';
import '../utils/format.dart';
import 'edit_timer_screen.dart';

/// Home: list of saved timers plus create / quick-start actions.
class HomeScreen extends StatelessWidget {
  final TimerStore store;

  /// Called when the user wants to run a timer. Wired to the running
  /// timer screen (stage 3).
  final void Function(BuildContext, TimerConfig) onStart;

  /// Optional settings action shown in the app bar (stage 5).
  final VoidCallback? onOpenSettings;

  const HomeScreen({
    super.key,
    required this.store,
    required this.onStart,
    this.onOpenSettings,
  });

  void _openEditor(BuildContext context, {TimerConfig? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditTimerScreen(store: store, existing: existing),
      ),
    );
  }

  void _quickStart(BuildContext context) {
    // Run a sensible default without saving anything.
    onStart(context, TimerConfig.preset('tabata', 'quick-start'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoundOne'),
        actions: [
          if (onOpenSettings != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: onOpenSettings,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('New timer'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (!store.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final timers = store.timers;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bolt, size: 32),
                  title: const Text('Quick start'),
                  subtitle: const Text('Tabata · 8 × 20s work / 10s rest'),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () => _quickStart(context),
                ),
              ),
              const SizedBox(height: 16),
              if (timers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'No timers yet.\nCreate one or use a preset.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                for (final t in timers)
                  Card(
                    child: ListTile(
                      title: Text(t.name),
                      subtitle: Text(
                        '${t.summary} · ${formatSeconds(t.totalSeconds)}',
                      ),
                      onTap: () => _openEditor(context, existing: t),
                      leading: IconButton.filledTonal(
                        icon: const Icon(Icons.play_arrow),
                        tooltip: 'Start',
                        onPressed: () => onStart(context, t),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) async {
                          switch (action) {
                            case 'duplicate':
                              await store.duplicate(t);
                            case 'delete':
                              await store.delete(t.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Text('Duplicate'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
