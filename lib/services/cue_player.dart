import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:vibration/vibration.dart';

import '../engine/workout_engine.dart';
import '../models/workout_schedule.dart';
import 'app_settings.dart';

/// Plays beeps and vibrations for workout cues.
///
/// Music-friendly by design: we configure an [AudioSession] that MIXES with
/// other audio and DUCKS it (briefly lowers Spotify/YouTube Music volume)
/// instead of pausing it. The session is deactivated shortly after each cue
/// so the music volume comes right back up.
class CuePlayer {
  final AppSettings settings;

  final ap.AudioPlayer _player = ap.AudioPlayer(playerId: 'fittimer_cues');
  AudioSession? _session;
  Timer? _deactivateTimer;
  bool _ready = false;

  CuePlayer(this.settings);

  Future<void> init() async {
    _session = await AudioSession.instance;
    await _session!.configure(AudioSessionConfiguration(
      // iOS: play even in silent-switch mode, mix + duck others.
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.mixWithOthers |
              AVAudioSessionCategoryOptions.duckOthers,
      // Android: transient focus that allows other apps to duck (not pause).
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        usage: AndroidAudioUsage.assistanceSonification,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransientMayDuck,
      androidWillPauseWhenDucked: false,
    ));

    // audioplayers must NOT manage audio focus itself, or it would fight
    // with audio_session and could pause the user's music.
    await ap.AudioPlayer.global.setAudioContext(ap.AudioContext(
      android: ap.AudioContextAndroid(
        audioFocus: ap.AndroidAudioFocus.none,
        contentType: ap.AndroidContentType.sonification,
        usageType: ap.AndroidUsageType.assistanceSonification,
      ),
      iOS: ap.AudioContextIOS(
        category: ap.AVAudioSessionCategory.playback,
        options: {
          ap.AVAudioSessionOptions.mixWithOthers,
          ap.AVAudioSessionOptions.duckOthers,
        },
      ),
    ));
    await _player.setReleaseMode(ap.ReleaseMode.stop);
    _ready = true;
  }

  Future<void> handleCue(WorkoutCue cue, WorkoutPosition position) async {
    switch (cue) {
      case WorkoutCue.phaseChange:
        await _play('sounds/phase.wav', deactivateAfterMs: 900);
        _vibrate(300);
      case WorkoutCue.countdown:
        await _play('sounds/countdown.wav', deactivateAfterMs: 700);
        _vibrate(80);
      case WorkoutCue.finish:
        await _play('sounds/finish.wav', deactivateAfterMs: 1600);
        _vibrate(700);
    }
  }

  Future<void> _play(String asset, {required int deactivateAfterMs}) async {
    if (!settings.soundEnabled || !_ready) return;
    // Take (duck) focus, play, then give focus back so music volume returns.
    _deactivateTimer?.cancel();
    await _session?.setActive(true);
    await _player.stop();
    await _player.play(ap.AssetSource(asset));
    _deactivateTimer = Timer(Duration(milliseconds: deactivateAfterMs), () {
      _session?.setActive(false);
    });
  }

  Future<void> _vibrate(int ms) async {
    if (!settings.vibrationEnabled) return;
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: ms);
    }
  }

  void dispose() {
    _deactivateTimer?.cancel();
    _session?.setActive(false);
    _player.dispose();
  }
}
