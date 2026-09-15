> Recording/FIT scope superseded by [ADR 007](007-local-only-no-recording.md).
> The user chose local only, no recording or phone/app transmission. No decision is pending.

# ADR 006 — Offline geographic grid and native activity recording

Date: 2026-09-15. Status: Accepted for implementation by user request.

## Authority and scope

The user explicitly replaced street maps with a geographic grid, requested GPS
jitter suppression and continuous activity information, and answered “hepsi” to
whether duration/distance/speed AND Garmin Connect activity recording were required.
This supersedes raster/network requirements and brings FIT recording forward from
R1. It does not authorize public deployment or pass physical G0/G3 gates.

## Decision

Use a locally drawn, north up WGS84 coordinate grid, pan/follow and zoom 10–19.
Keep the existing app ID/PRG filename for upgrades; display FieldGrid G0 v0.2.0.
Remove Communications, map jobs, bitmap conversion, metadata and private build URL
resources. Add Fit permission and one ActivityRecording session. Keep Python raster
code as a separately documented historical experiment rather than deleting evidence.

Raw accepted lat/lon, quality and age belong to GpsState. A separate display filter
holds three samples, uses a median, then a quality dependent 4/7 m hold radius and
speed hysteresis. Speed >=0.5 m/s in two evaluated samples can release a >=2 m hold;
three <0.25 m/s samples stop the moving state. Moving smoothing uses dt/(1+dt).
Null speed falls back to displacement. These are chosen heuristics, not Garmin
accuracy specifications; QUALITY_GOOD is a category, not a meter uncertainty.

A jump farther than 40 + 15*dt meters from the display anchor requires three fixes
within 15 m of each other. Reacquisition, unusable GPS, >5 s gaps and explicit
pause/resume create trace breaks. Trace points require >=3 m displacement, or >=1 m
after 5 s; time alone never grows a stationary trace. Ring capacity is 180.

An alternative, a Kalman filter, would require an uncertainty model that the device
quality categories do not provide. Start with this small, testable filter and tune
only from explicit physical evidence. It cannot eliminate persistent drift without
also hiding some slow movement. GPS only distance is a filtered approximation.

Recording uses ActivityRecording.createSession and Activity sport constants from
SDK 9.2.0. start/stop/save/discard return Boolean: false/exception retains the handle
and an error for retry. Discard is confirmed in app. Normal exit via BACK pauses;
OS exit best effort saves. Native Garmin owns the FIT track and recording statistics;
filtered coordinates are never written into native records. Saved FIT data grows
on disk intentionally; this app does not duplicate it in a database.

AppBase.onInactive means hidden by the system, not ordinary inactivity of the user.
Garmin documents limited GPS access then. Release UI GPS/timer, preserve native FIT;
re subscribe onActive only if still running. Do not promise background/battery
behavior from a simulator test. No separate background service is registered.

## Validation and migration

Compile and run tests only for fr165; test stationary noise, walking speeds, turns,
spikes, antimeridian, stale quality, ring wrap, save failures and resource release.
Native simulator FIT start/pause/resume/save/discard and English layout checks are
separate from physical sync, field accuracy, battery and endurance acceptance.

The subsequent no persistence request removes all saved preferences. Known old keys
(grid preferences v1, preferences v1, g0-probe) are deleted on app initialization;
no new application storage is written. Builds
no longer embed old URLs/tokens even if local experiment files remain. Reinstalling
the new PRG replaces old executable behavior; until then a watch may still run the
old expired tunnel map build. Rollback requires a deliberately configured old build;
its public test URL has expired. No firmware or user activities are removed.

## Verified SDK references

- SDK 9.2.0 `doc/Toybox/Position/Info.html`: optional speed m/s, quality enums.
- `doc/Toybox/ActivityRecording.html`, `Session.html`: Fit permission, session methods.
- `doc/Toybox/Activity/Info.html`: elapsedDistance m, currentSpeed m/s, optional HR.
- `doc/Toybox/Application/AppBase.html`: onActive/onInactive/onStop lifecycle.
- `doc/Toybox/Graphics/Dc.html`: clipping and drawing; native vector font API on fr165.

The restored SDK archive matched toolchain.lock.json SHA-256. No SDK copy is in Git.

## Follow up: delete after sync

The user additionally requested no watch data accumulation and deletion after sync.
The SDK has no notification proving successful Garmin Connect sync and no operation
for removing an already saved ActivityRecording FIT. `discard()` is for an unfinished
session, not for a previously saved file. PersistedContent tracks/courses describe
imported content and are not a saved activity deletion API. Never treat phoneConnected
as proof of successful upload or delete records on an arbitrary timer.

App preferences/history/cache persistence is removed now. Whether to retain native
FIT recording with manual watch history deletion, or remove activity persistence,
requires the user's answer. No watch deployment while this choice is pending.
