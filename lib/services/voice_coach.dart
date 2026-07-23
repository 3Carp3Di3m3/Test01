import 'package:flutter_tts/flutter_tts.dart';

import '../engine/workout_engine.dart';
import '../models/workout_schedule.dart';
import 'app_settings.dart';

/// Speaks short coaching cues over the workout using text-to-speech.
///
/// Cross-platform (Android + iOS). Configured to mix/duck with music rather
/// than take it over, and to interrupt its own previous utterance so cues
/// never pile up if phases change quickly.
class VoiceCoach {
  final AppSettings settings;
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  VoiceCoach(this.settings);

  Future<void> init() async {
    try {
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      // iOS: play alongside other audio and duck it, matching the beeps.
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  Future<void> handleCue(WorkoutCue cue, WorkoutPosition position) async {
    if (!settings.voiceEnabled || !_ready) return;
    final phrase = switch (cue) {
      WorkoutCue.phaseChange => _phraseForPhase(position.interval),
      WorkoutCue.finish => 'Workout complete',
      WorkoutCue.countdown => null, // beeps handle the 3-2-1
    };
    if (phrase == null) return;
    try {
      // Interrupt any previous utterance so cues stay in sync with phases.
      await _tts.stop();
      await _tts.speak(phrase);
    } catch (_) {
      // A failed announcement must never disrupt the workout.
    }
  }

  String _phraseForPhase(WorkoutInterval interval) {
    switch (interval.phase) {
      case PhaseType.warmup:
        return 'Warm up';
      case PhaseType.prepare:
        return 'Get ready';
      case PhaseType.work:
        return 'Work. Round ${interval.round}';
      case PhaseType.rest:
        return 'Rest';
      case PhaseType.setRest:
        return 'Set complete. Rest';
      case PhaseType.cooldown:
        return 'Cool down';
      case PhaseType.done:
        return 'Done';
    }
  }

  void dispose() {
    _tts.stop();
  }
}
