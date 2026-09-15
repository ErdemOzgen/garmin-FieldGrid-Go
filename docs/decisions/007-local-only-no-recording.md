# ADR 007 — Local only grid with no activity recording

Date: 2026-09-15. Status: Accepted by explicit user instruction.

## Scope

The user selected **grid and live information without recording** and explicitly requested that
nothing be sent to the phone or an app. This supersedes the recording, FIT and sync
parts of ADR 006. Its coordinate grid, filtering and bounded trace remain applicable.
There is no pending recording retention question.

## Implementation

- Manifest grants only Positioning. No Fit, Communications or Background permission.
- Remove RecordingController, native Activity/ActivityRecording dependencies, sport
  profiles, FIT session/save/discard methods and recording related UI. There is no
  path that creates an activity that Garmin Connect could upload.
- GPS only session computes active duration locally, estimates distance from filtered
  trace segments, and displays Position.Info speed (m/s -> km/h) and derived pace.
  Stationary hold shows zero speed; stale/reacquiring/missing speed is unavailable.
  No HR subscription or additional sensor permission is needed for these metrics.
- Home START opens grid; DOWN opens raw coordinates. Both explicitly start GPS.
  BACK on grid pauses and offers Resume or End session. End and app exit clear all
  session coordinates, trace, counters and duration from app state; nothing is saved.
- No new application storage writes or network APIs. The three obsolete app owned
  preference/probe keys are removed on upgrade; existing Garmin activities are untouched.
- One 1 Hz timer requests redraws; GPS callbacks update bounded state without a second
  repaint cadence. At most 180 trace points and three filter samples remain in RAM.
- System hidden state releases GPS/timer. Foreground resumes only an active session,
  with a trace gap. Explicit pause freezes elapsed time; End prevents later auto resume.
  The active session clock can continue while hidden, but no missing distance is guessed.

## Boundaries and verification

The app sends no session data to Garmin Connect, another phone app or a server.
This does not change the watch's independent built in activity/health sync settings.
The application executable itself occupies storage; user session data is never persisted.

Keep app ID/PRG filename for upgrade; display FieldGrid G0 v0.2.1. Python renderer is
historical source only, neither running nor packaged into the watch. Static contract
checks enforce Positioning only permissions, no recording/phone modules, no private
server resources and no Storage.setValue call. Monkey C tests cover lifecycle, buttons,
filtered metrics, GPS gaps, bounded memory and layout; physical acceptance remains separate.

APIs checked against installed SDK 9.2.0: Position.Info.speed and accuracy;
Position.enableLocationEvents; Application.AppBase.onActive/onInactive/onStop;
Timer.Timer and Graphics native fonts/clipping. Compile/test target remains fr165.
