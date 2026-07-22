String _two(int v) => v.toString().padLeft(2, '0');

/// Formats a number of seconds for compact display: "45s" under a minute,
/// "3:00" from a minute up, "1:02:05" from an hour up.
String formatSeconds(int seconds) {
  if (seconds < 60) return '${seconds}s';
  return formatClock(seconds);
}

/// Formats seconds as clock digits for the running timer: "0:07", "19:59".
String formatClock(int seconds) {
  if (seconds < 0) seconds = 0;
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '$h:${_two(m)}:${_two(s)}';
  return '$m:${_two(s)}';
}
