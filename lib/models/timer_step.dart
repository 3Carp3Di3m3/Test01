/// One step in a custom interval sequence, e.g. "Push-ups, 30s, work".
class TimerStep {
  final String name;
  final String iconKey;
  final int seconds;

  /// Rest steps are colored like a rest phase; work steps like a work phase.
  final bool isRest;

  const TimerStep({
    required this.name,
    this.iconKey = 'dumbbell',
    this.seconds = 30,
    this.isRest = false,
  });

  TimerStep copyWith({
    String? name,
    String? iconKey,
    int? seconds,
    bool? isRest,
  }) {
    return TimerStep(
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      seconds: seconds ?? this.seconds,
      isRest: isRest ?? this.isRest,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'iconKey': iconKey,
        'seconds': seconds,
        'isRest': isRest,
      };

  factory TimerStep.fromJson(Map<String, dynamic> json) => TimerStep(
        name: json['name'] as String? ?? 'Step',
        iconKey: json['iconKey'] as String? ?? 'dumbbell',
        seconds: json['seconds'] as int? ?? 30,
        isRest: json['isRest'] as bool? ?? false,
      );
}
