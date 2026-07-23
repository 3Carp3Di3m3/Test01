import 'package:flutter/material.dart';

import '../models/timer_config.dart';
import '../services/timer_store.dart';
import '../utils/format.dart';
import 'edit_timer_screen.dart';

/// Home: list of saved timers plus create / quick-start actions.
class HomeScreen extends StatelessWidget {
  final TimerStore store;

  /// Called when the user wants to run a timer. Wired to the running
  /// timer screen.
  final void Function(BuildContext, TimerConfig) onStart;

  /// Optional settings action shown in the app bar.
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
    onStart(context, TimerConfig.preset('tabata', 'quick-start'));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (!store.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final timers = store.timers;
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList.list(
                  children: [
                    _QuickStartCard(onTap: () => _quickStart(context)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Text(
                          'Your timers',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        if (timers.isNotEmpty)
                          Text(
                            '${timers.length}',
                            style: TextStyle(color: scheme.outline),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (timers.isEmpty)
                      _EmptyState(scheme: scheme)
                    else
                      for (final t in timers)
                        _TimerCard(
                          config: t,
                          onStart: () => onStart(context, t),
                          onEdit: () => _openEditor(context, existing: t),
                          onDuplicate: () => store.duplicate(t),
                          onDelete: () => store.delete(t.id),
                        ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: const Text('New timer'),
      ),
    );
  }
}

class _QuickStartCard extends StatelessWidget {
  final VoidCallback onTap;
  const _QuickStartCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: scheme.primaryContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.bolt, size: 34, color: scheme.onPrimary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick start',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                    Text(
                      'Tabata · 8 × 20s / 10s',
                      style: TextStyle(color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_fill,
                  size: 40, color: scheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  final TimerConfig config;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _TimerCard({
    required this.config,
    required this.onStart,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerHighest,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
          child: Row(
            children: [
              // Big play button with a work-green accent.
              Material(
                color: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onStart,
                  child: const SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(Icons.play_arrow,
                        color: Colors.white, size: 34),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      config.summary,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 14, color: scheme.outline),
                        const SizedBox(width: 4),
                        Text(
                          formatSeconds(config.totalSeconds),
                          style: TextStyle(
                              color: scheme.outline, fontSize: 13),
                        ),
                        if (config.warmupSeconds > 0 ||
                            config.cooldownSeconds > 0) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.self_improvement,
                              size: 14, color: scheme.outline),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (action) {
                  switch (action) {
                    case 'duplicate':
                      onDuplicate();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'duplicate',
                    child: ListTile(
                      leading: Icon(Icons.copy),
                      title: Text('Duplicate'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Delete'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme scheme;
  const _EmptyState({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.timer_outlined, size: 64, color: scheme.outline),
          const SizedBox(height: 12),
          Text(
            'No timers yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap “New timer” or use a preset',
            style: TextStyle(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}
