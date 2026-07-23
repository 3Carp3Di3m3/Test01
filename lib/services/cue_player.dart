import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:vibration/vibration.dart';

import '../engine/workout_engine.dart';
import '../models/workout_schedule.dart';
import 'app_settings.dart';

/// Plays beeps and vibrations for workout cues.
///
/// Music-friendly by design: while a beep plays we hold *transient, may-duck*
/// audio focus, so the user's music (Spotify, etc.) briefly lowers in volume
/// and then returns to full — it is never paused or stopped. The focus is
/// released a short moment after the beep, which is what restores the volume.
class CuePlayer {
  final AppSettings settings;

  final ap.AudioPlayer _player = ap.AudioPlayer(playerId: 'fittimer_cues');
  AudioSession? _session;
  Timer? _restoreTimer;
  bool _ready = false;

  CuePlayer(this.settings);

  Future<void> init() async {
    _session = await AudioSession.instance;
    await _session!.configure(AudioSessionConfiguration(
      // iOS: audible even with the silent switch, mix + duck other audio.
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.mixWithOthers |
              AVAudioSessionCategoryOptions.duckOthers,
      // Android: request focus that DUCKS other audio (lowers its volume)
      // rather than pausing/stopping it.
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        usage: AndroidAudioUsage.assistanceSonification,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: false,
    ));

    // CRITICAL: audioplayers' default Android focus is AUDIOFOCUS_GAIN, which
    // makes us the sole audio source and STOPS the user's music. We must set
    // our own context to "no focus" so the only thing touching audio focus is
    // the audio_session above (which merely ducks). And we must set it on THIS
    // player instance, not only the global default — the player was created
    // before this runs, so it still carries the stop-the-music default until
    // we override it right here.
    final context = ap.AudioContext(
      android: ap.AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: ap.AndroidContentType.sonification,
        usageType: ap.AndroidUsageType.assistanceSonification,
        audioFocus: ap.AndroidAudioFocus.none,
      ),
      iOS: ap.AudioContextIOS(
        category: ap.AVAudioSessionCategory.playback,
        options: const {
          ap.AVAudioSessionOptions.mixWithOthers,
          ap.AVAudioSessionOptions.duckOthers,
        },
      ),
    );
    await ap.AudioPlayer.global.setAudioContext(context);
    await _player.setAudioContext(context);
    await _player.setReleaseMode(ap.ReleaseMode.stop);
    _ready = true;
  }

  Future<void> handleCue(WorkoutCue cue, WorkoutPosition position) async {
    switch (cue) {
      case WorkoutCue.phaseChange:
        await _play('sounds/phase.wav');
        _vibrate(300);
      case WorkoutCue.countdown:
        await _play('sounds/countdown.wav');
        _vibrate(80);
      case WorkoutCue.finish:
        await _play('sounds/finish.wav', keepDuckedMs: 1800);
        _vibrate(700);
    }
  }

  /// Duck the music, play the beep, then release focus [keepDuckedMs] later so
  /// the music volume comes back. The default window comfortably spans the gap
  /// between the 3-2-1 countdown beeps (1s apart), so each new beep extends the
  /// duck instead of letting the volume bob up and down between them.
  Future<void> _play(String asset, {int keepDuckedMs = 1400}) async {
    if (!settings.soundEnabled || !_ready) return;
    try {
      _restoreTimer?.cancel();
      await _session?.setActive(true);
      await _player.stop();
      await _player.play(ap.AssetSource(asset), volume: 1.0);
      _restoreTimer = Timer(Duration(milliseconds: keepDuckedMs), () {
        _session?.setActive(false);
      });
    } catch (_) {
      // A failed cue must never crash or interrupt the workout.
    }
  }

  Future<void> _vibrate(int ms) async {
    if (!settings.vibrationEnabled) return;
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: ms);
      }
    } catch (_) {}
  }

  void dispose() {
    _restoreTimer?.cancel();
    _session?.setActive(false);
    _player.dispose();
  }
}
