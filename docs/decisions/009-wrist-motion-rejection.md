# ADR 009 — Confirm walking before releasing a held position

Date: 2026-09-15. Status: Implemented in v0.2.3; limited physical standing/walking check PASS by user report.

## Field evidence and cause

The user reports that v0.2.2 improved stationary behavior but still drifted 7 to
11 meters when the arm moved slightly. This is a physical stationary acceptance
FAIL, not a complete pass. The diagnostic Motion value was not supplied.

Two weaknesses are verified in code and reproduced with synthetic regressions.
Axis variance includes rotation of the gravity vector, so a wrist turn can appear
to be travel. A single active batch or single step increment also grants movement
permission. Fresh measurements between the quiet and active thresholds returned
unknown, allowing the GPS filter to release the hold on its own.

## Correction

The GPS coordinate filter, trace bounds and speed checks from ADR 008 remain.
MotionState now computes vector magnitude, which is invariant under pure rotation
of gravity. A scalar moving baseline removes its steady component. Positive peaks
above 45 mg must reset below minus 15 mg before another peak can be counted.
Four peaks with three consistent intervals between 300 and 2000 milliseconds
provide gait evidence. Intervals can vary by at most 45 percent or 180 ms. Gait
evidence expires 2.2 seconds after its last qualifying peak.

At least three new native steps within six seconds provide four seconds of step
evidence. One or two isolated increments cannot release the hold. The initial
count, missing value and midnight reset establish a new baseline. There is no
assumption that Garmin publishes each step immediately.

While acceleration data is fresh and valid, unconfirmed motion keeps the position
held. Only missing, invalid, stale or disabled motion input falls back to GPS.
Diagnostics distinguishes these cases:

| Motion label | Meaning |
| :--- | :--- |
| STILL | Four quiet magnitude batches; position remains held |
| VERIFY | Fresh sensor input, but movement is not yet confirmed; position remains held |
| GAIT | Repeated acceleration peaks confirm a plausible walking or running rhythm |
| STEPS | Multiple recent native steps provide movement evidence |
| WAIT | Sensor evidence is absent or stale; GPS filtering is used |
| UNAVAILABLE | Sensor registration failed; GPS filtering is used |
| OFF | User disabled assistance for this session |

Sensor evidence permits movement checks; it cannot create GPS coordinates or
bypass GPS validity, speed and directional progress checks. No acceleration is
integrated into distance. Raw coordinates remain available under their explicit
label. This correction changes no network, storage, recording or sync behavior.

## Cost, alternatives and limits

The same 25 Hz stream and one second batches are retained. Only scalar state is
added; at most 25 samples per axis are processed and then discarded. A callback gap
above 1.5 seconds resets cadence evidence. Existing end, pause and inactive cleanup
releases the state and listener. No new timer, permission or dependency is required.

Raising an amplitude threshold alone would miss quiet walking and still misread
wrist rotation. Relying only on Garmin's step counter would inherit its unspecified
update latency. The selected combination preserves both sources while rejecting
isolated evidence. It can take several initial steps to confirm a slow walk.

Periodic wrist motion that resembles gait, combined with plausible GPS drift,
can still be ambiguous. A delayed native step batch can briefly grant permission
after stopping. A steady wrist, shuffling, cycling or movement without steps can
be suppressed; Diagnostics START retains the option to disable assistance. Neither
sensor fusion nor this heuristic guarantees absolute GPS accuracy. Thresholds are
prototype choices; physical battery and outdoor behavior require measurement.

## Verification

Before correction: 32 existing tests PASS; two new wrist/step regressions report
assertion errors. After correction: 37 fr165 tests PASS, including rotation,
isolated arm pulses, small vibrations, fast vibration, native step debouncing,
gait from 0.6 to 2.8 Hz, walking at 0.35 m/s, running, missing sensors and cleanup.
These are synthetic inputs, not a recording of the user's arm movement.

The user confirms stationary position now holds and walking advances. No numerical
accuracy or battery measurement was supplied. The 126,620 byte production PRG builds without warnings and has been read back
identically from the physical watch. Python tests: 116 PASS. No full G0/G3 pass is
inferred. See [evidence](../evidence/wrist-motion/README.md).
