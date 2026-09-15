# ADR 008 — Stationary hold with motion evidence

Date: 2026-09-15. Status: Superseded in part by ADR 009 after physical stationary failure.

The user later reported 7 to 11 m drift with slight arm movement. The classifier
below describes v0.2.2; [ADR 009](009-wrist-motion-rejection.md) replaces its movement
confirmation behavior.

## Problem and authorization

The user reports 12 to 34 meters of drift while standing still, with both the blue
marker and distance changing in v0.2.1. That physical stationary check is FAIL by
user report. A small synthetic noise test had passed but did not cover this range.
The user subsequently authorized support from other watch sensors. Recording,
phone transmission and persistent storage remain excluded by ADR 007.

The original filter set `moving = false` for low speed and then immediately allowed
coordinate displacement to set it to true again. Two new regressions reproduced
this defect before the fix: 20 tests passed and two assertion errors were reported.

## GPS behavior

- Keep a median of three coordinates and three speed values. A speed below
  0.25 m/s holds the marker; displacement alone cannot override that decision.
- Releasing the hold requires consistent displacement and sustained speed of at
  least 0.30 m/s. A bounded 12 second confirmation window prevents arbitrarily
  slow drift from eventually crossing a fixed radius. Directional progress must
  be at least 80 percent of the path in that window.
- If speed is missing, require at least five seconds of directional progress,
  4 m at GOOD quality or 7 m at USABLE quality, and an average of 0.25 m/s.
  This conservative fallback can delay or miss very slow movement.
- Retain smoothing, spike rejection, stale fix handling and gaps. If GPS acquires
  a new baseline during a hold, exclude the excess offset when walking resumes.
  Do not draw or accumulate a segment across a rebase.
- Display filtered WGS84 coordinates by default; START toggles explicitly labeled
  raw coordinates. Both use six decimals. Filtering does not improve the sensor's
  absolute accuracy, and decimal precision is not an accuracy guarantee.

## Motion assistance

Use the documented Sensor accelerometer stream at 25 Hz in one second batches,
plus the current ActivityMonitor step counter. Sensor is the only added permission.
Positioning remains required. No heart rate, compass or barometer stream is enabled:
none is needed to decide whether the wrist is stationary.

Process at most 25 samples on each axis per callback. Compute total axis variance
with Welford's algorithm, then discard the arrays. Four consecutive quiet batches
below 18 mg combined RMS indicate stillness; at least 50 mg RMS provides recent
motion evidence. The band between these thresholds is unknown. Reject invalid,
empty, oversized or implausible zero gravity input, and expire acceleration
summaries after 2.5 seconds. These are prototype thresholds requiring field tests.

A step increase supplies eight seconds of movement evidence, including when the
wrist is steady. The initial daily count, midnight reset and missing values only
establish a baseline. Garmin does not promise an immediate step update, so absence
of a step increase is never used on its own to declare stillness. No daily total is
shown, logged, saved or transmitted.

Fresh stillness evidence vetoes GPS motion, even when GPS reports a misleading
speed. Motion evidence cannot manufacture a position or override invalid GPS.
Unavailable or stale sensor evidence falls back to the GPS filter. Acceleration is
never integrated into distance or coordinates. This is not Garmin's proprietary
activity fusion algorithm and does not claim equivalent performance.

Diagnostics START toggles motion assistance for the current session. Turn it off
if a steady wrist or an activity without steps causes legitimate motion to be
suppressed. The next session defaults to enabled. Registration occurs only after
explicit START or DOWN. Pause, exit and system inactivity unregister the sensor,
stop GPS and stop the timer; a running foreground session can subscribe again.

## Resources and acceptance

Retain only scalar motion summaries, three GPS samples, fixed filter anchors and
at most 180 trail points. Sensor callbacks do not trigger redraws. No extra timer,
background task, application storage writer, FIT recorder or network API is added.
The executable occupies storage; the sensor adds active processing and its battery
cost must be measured on the watch. Simulation cannot establish physical endurance.

Verification covers the previously failing drift, inaccurate speed with still
acceleration, missing sensors, steps and midnight, slow walking, walking after
34 m drift, screen modes, and repeated sensor/GPS lifecycles. See the
[evidence](../evidence/stationary-filter/README.md). New physical behavior is NOT RUN
until this exact build is installed and tested; no full G0/G3 PASS is inferred.

## Verified API references

Checked against installed SDK 9.2.0 documentation and compiled for `fr165`:

- [Position.Info](https://developer.garmin.com/connect-iq/api-docs/Toybox/Position/Info.html): nullable speed in m/s and categorical quality, not error radius in meters.
- [Sensor](https://developer.garmin.com/connect-iq/api-docs/Toybox/Sensor.html): register and unregister the sensor data listener; Forerunner 165 is supported.
- [AccelerometerData](https://developer.garmin.com/connect-iq/api-docs/Toybox/Sensor/AccelerometerData.html): axis arrays in milli G units.
- [ActivityMonitor.Info](https://developer.garmin.com/connect-iq/api-docs/Toybox/ActivityMonitor/Info.html): nullable step count since local midnight.
