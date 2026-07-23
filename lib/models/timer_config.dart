/// Data model for a saved workout timer configuration.
///
/// This is pure Dart (no Flutter imports) so it can be unit-tested
/// without a device and reused on any platform.
class TimerConfig {
  final String id;
  final String name;

  /// "Get ready" time before the first work interval, in seconds.
  final int prepareSeconds;

  /// Optional gentle warm-up before everything else, in seconds. 0 = none.
  final int warmupSeconds;

  /// Optional cool-down after the last round, in seconds. 0 = none.
  final int cooldownSeconds;

  /// Length of one work interval, in seconds.
  final int workSeconds;

  /// Rest between rounds, in seconds. May be 0 (no rest).
  final int restSeconds;

  /// Number of work rounds per set.
  final int rounds;

  /// Number of sets. The whole round structure repeats once per set.
  final int sets;

  /// Rest between sets, in seconds.
  final int setRestSeconds;

  const TimerConfig({
    required this.id,
    required this.name,
    this.prepareSeconds = 10,
    this.warmupSeconds = 0,
    this.cooldownSeconds = 0,
    this.workSeconds = 20,
    this.restSeconds = 10,
    this.rounds = 8,
    this.sets = 1,
    this.setRestSeconds = 60,
  });

  /// Total workout duration in seconds.
  ///
  /// Rules:
  ///  * warm-up (if any) happens once, first of all;
  ///  * prepare happens once, right after the warm-up;
  ///  * within a set there is no rest after the last round;
  ///  * set-rest happens between sets, not after the last one;
  ///  * cool-down (if any) happens once, at the very end.
  int get totalSeconds {
    final oneSet = rounds * workSeconds + (rounds - 1).clamp(0, 1 << 30) * restSeconds;
    final betweenSets = (sets - 1).clamp(0, 1 << 30) * setRestSeconds;
    return warmupSeconds +
        prepareSeconds +
        sets * oneSet +
        betweenSets +
        cooldownSeconds;
  }

  /// Short human-readable summary, e.g. "8 × 20s work / 10s rest · 2 sets".
  String get summary {
    final base = '$rounds × ${_fmt(workSeconds)} work / ${_fmt(restSeconds)} rest';
    return sets > 1 ? '$base · $sets sets' : base;
  }

  static String _fmt(int seconds) {
    if (seconds >= 60 && seconds % 60 == 0) return '${seconds ~/ 60}min';
    return '${seconds}s';
  }

  TimerConfig copyWith({
    String? id,
    String? name,
    int? prepareSeconds,
    int? warmupSeconds,
    int? cooldownSeconds,
    int? workSeconds,
    int? restSeconds,
    int? rounds,
    int? sets,
    int? setRestSeconds,
  }) {
    return TimerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      prepareSeconds: prepareSeconds ?? this.prepareSeconds,
      warmupSeconds: warmupSeconds ?? this.warmupSeconds,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      workSeconds: workSeconds ?? this.workSeconds,
      restSeconds: restSeconds ?? this.restSeconds,
      rounds: rounds ?? this.rounds,
      sets: sets ?? this.sets,
      setRestSeconds: setRestSeconds ?? this.setRestSeconds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'prepareSeconds': prepareSeconds,
        'warmupSeconds': warmupSeconds,
        'cooldownSeconds': cooldownSeconds,
        'workSeconds': workSeconds,
        'restSeconds': restSeconds,
        'rounds': rounds,
        'sets': sets,
        'setRestSeconds': setRestSeconds,
      };

  factory TimerConfig.fromJson(Map<String, dynamic> json) => TimerConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        prepareSeconds: json['prepareSeconds'] as int? ?? 0,
        warmupSeconds: json['warmupSeconds'] as int? ?? 0,
        cooldownSeconds: json['cooldownSeconds'] as int? ?? 0,
        workSeconds: json['workSeconds'] as int? ?? 20,
        restSeconds: json['restSeconds'] as int? ?? 0,
        rounds: json['rounds'] as int? ?? 1,
        sets: json['sets'] as int? ?? 1,
        setRestSeconds: json['setRestSeconds'] as int? ?? 0,
      );

  /// Built-in preset templates shown on the setup screen.
  static TimerConfig preset(String kind, String id) {
    switch (kind) {
      case 'tabata':
        return TimerConfig(
          id: id,
          name: 'Tabata',
          prepareSeconds: 10,
          workSeconds: 20,
          restSeconds: 10,
          rounds: 8,
          sets: 1,
          setRestSeconds: 60,
        );
      case 'hiit':
        return TimerConfig(
          id: id,
          name: 'HIIT',
          prepareSeconds: 10,
          workSeconds: 40,
          restSeconds: 20,
          rounds: 10,
          sets: 1,
          setRestSeconds: 60,
        );
      case 'boxing':
        return TimerConfig(
          id: id,
          name: 'Boxing',
          prepareSeconds: 10,
          workSeconds: 180,
          restSeconds: 60,
          rounds: 12,
          sets: 1,
          setRestSeconds: 60,
        );
      default:
        return TimerConfig(
          id: id,
          name: 'Custom',
          prepareSeconds: 10,
          workSeconds: 30,
          restSeconds: 15,
          rounds: 5,
          sets: 1,
          setRestSeconds: 60,
        );
    }
  }
}
