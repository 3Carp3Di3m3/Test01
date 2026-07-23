# FitTimer

A customizable workout interval timer built with Flutter. Set up intervals
(get-ready / work / rest), rounds and sets, then run a full-screen timer that
guides you through the workout with colors, sounds and vibration.

- Android-first, but everything is cross-platform — the same code builds for iOS.
- No ads, no accounts, no internet. Everything is stored locally.
- Material 3 with automatic dark mode.

## Project structure

```
lib/
  main.dart                     # App entry: theme, wiring of all services
  models/
    timer_config.dart           # A saved timer (warm-up/work/rest/cool-down) + presets
    workout_schedule.dart       # Expands a timer into intervals; "what phase at second X"
    workout_record.dart         # One completed workout, for history
  engine/
    workout_engine.dart         # Wall-clock driven engine: pause/skip/cues
  services/
    timer_store.dart            # Saved timers (shared_preferences, JSON)
    history_store.dart          # Completed-workout log + stats
    app_settings.dart           # Sound / voice / vibration / keep-awake / theme
    cue_player.dart             # Beeps + vibration, ducks music via audio_session
    voice_coach.dart            # Spoken cues via flutter_tts (ducks music too)
    foreground_service.dart     # Android foreground service + notification
    running_session_store.dart  # Persists a running workout for resume-after-kill
  screens/
    home_screen.dart            # Saved timers, quick start, create new
    edit_timer_screen.dart      # Sectioned steppers, presets, live total duration
    run_screen.dart             # Colored timer, progress ring, completion summary
    history_screen.dart         # Workout history + summary stats
    settings_screen.dart        # Sound/voice/vibration/keep-awake + theme picker
  widgets/
    stepper_row.dart            # +/− control with hold-to-repeat
  utils/format.dart             # Time + relative-date formatting helpers
test/
  workout_schedule_test.dart    # Duration + phase-lookup unit tests
  format_test.dart              # Time + relative-date formatting tests
assets/sounds/                  # Synthesized beep/finish WAV files
assets/icon/                    # App icon source art
```

### How the timer stays accurate (the important part)

The engine **never counts ticks**. A monotonic `Stopwatch` measures elapsed
time, and every UI refresh *recomputes* the current phase and remaining time
from that elapsed value using the precomputed interval schedule
(`WorkoutSchedule.positionAt`). The 100 ms periodic timer only refreshes the
display — if the app is backgrounded, throttled or ticks are missed, the next
tick still shows the correct time. Resume-after-kill works the same way: we
persist "elapsed seconds + timestamp of the save" and recompute on restore.

Other reliability pieces:

- **Foreground service** (`flutter_foreground_task`): while a workout runs,
  a persistent notification keeps the process alive and un-throttled with the
  screen off. Declared with `foregroundServiceType="mediaPlayback"` for
  Android 14+, and the notification permission is requested on Android 13+.
- **Wakelock** (`wakelock_plus`): keeps the screen on during a workout
  (toggle in settings).
- **Audio ducking** (`audio_session`): cue beeps *mix with and duck* your
  music instead of pausing it; the session is deactivated right after each
  cue so the music volume comes back.

## Run it (development)

```bash
flutter pub get
flutter test          # unit tests
flutter run           # with a device/emulator connected
```

## Test on a real Android phone (USB debugging)

1. On the phone: **Settings → About phone → tap "Build number" 7 times** to
   enable Developer options.
2. **Settings → System → Developer options → enable "USB debugging".**
3. Connect the phone by USB cable. On the phone, accept the
   "Allow USB debugging?" prompt.
4. On the computer run `flutter devices` — your phone should be listed.
5. Run `flutter run` (or press Run in VS Code / Android Studio). First build
   takes a few minutes; the app installs and launches on the phone.
6. Try: create a timer, start it, switch the screen off mid-workout — the
   beeps must keep coming; play Spotify and check the music only dips briefly
   at each beep; kill the app mid-workout, reopen, and accept "Resume workout?".

## Release build for Google Play (later)

1. Create a keystore once:
   `keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Create `android/key.properties` with the keystore path/passwords and add
   the signing config to `android/app/build.gradle.kts`
   (see https://docs.flutter.dev/deployment/android — "Sign the app").
3. Pick your final application id (currently `com.tkalec.fittimer` in
   `android/app/build.gradle.kts`) — it can't be changed after first upload.
4. Build the bundle: `flutter build appbundle` → upload
   `build/app/outputs/bundle/release/app-release.aab` in the Google Play
   Console (create the app listing, screenshots, content rating, etc.).
