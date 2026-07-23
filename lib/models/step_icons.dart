import 'package:flutter/material.dart';

/// Named icons a custom step can use, kept as stable string keys so they
/// survive JSON round-trips and future icon changes.
const Map<String, IconData> kStepIcons = {
  'dumbbell': Icons.fitness_center,
  'run': Icons.directions_run,
  'bike': Icons.directions_bike,
  'jump': Icons.sports_gymnastics,
  'heart': Icons.favorite,
  'timer': Icons.timer_outlined,
  'rest': Icons.self_improvement,
  'pause': Icons.pause_circle_outline,
  'stretch': Icons.accessibility_new,
  'plank': Icons.airline_seat_flat,
  'boxing': Icons.sports_mma,
  'water': Icons.local_drink,
  'fire': Icons.local_fire_department,
  'star': Icons.star,
  'bolt': Icons.bolt,
};

IconData stepIcon(String key) => kStepIcons[key] ?? Icons.fitness_center;
