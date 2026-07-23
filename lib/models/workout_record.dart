/// A single completed workout, logged to history.
class WorkoutRecord {
  final String timerName;

  /// When the workout finished (milliseconds since epoch, UTC).
  final int completedAtMs;

  /// Planned total duration of the workout, in seconds.
  final int durationSeconds;

  /// Number of work rounds × sets completed.
  final int totalRounds;

  const WorkoutRecord({
    required this.timerName,
    required this.completedAtMs,
    required this.durationSeconds,
    required this.totalRounds,
  });

  DateTime get completedAt =>
      DateTime.fromMillisecondsSinceEpoch(completedAtMs);

  Map<String, dynamic> toJson() => {
        'timerName': timerName,
        'completedAtMs': completedAtMs,
        'durationSeconds': durationSeconds,
        'totalRounds': totalRounds,
      };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
        timerName: json['timerName'] as String? ?? 'Workout',
        completedAtMs: json['completedAtMs'] as int? ?? 0,
        durationSeconds: json['durationSeconds'] as int? ?? 0,
        totalRounds: json['totalRounds'] as int? ?? 0,
      );
}
