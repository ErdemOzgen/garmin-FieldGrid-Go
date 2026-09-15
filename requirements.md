# FieldGrid requirements

Version 0.2.3 · 15 September 2026 · Current product scope

The user chose an offline coordinate grid and live information without recording
or sending data anywhere. This document and [ADR 007](docs/decisions/007-local-only-no-recording.md)
replace the earlier map, account, FIT and sync requirements. The earlier raster
implementation remains documented in [the historical overview](docs/archive/raster-readme.md)
for traceability. It is not the active implementation plan.

## Product

A Connect IQ Watch App for the Garmin Forerunner 165, with English text on its
round 390 × 390 display. The app uses the watch GPS and runs without a phone,
internet connection, API token, server or account. Display name: FieldGrid G0.
The verified SDK target is `fr165`; another watch model is not a substitute.

## Required behavior

| ID | Requirement |
| :--- | :--- |
| GRID01 | GPS starts only after START opens the grid or DOWN opens coordinates. Home alone must not start GPS. |
| GRID02 | Show a north up grid anchored to WGS84 coordinates, with readable degree labels and a scale in ground meters. |
| GRID03 | Support zoom levels 10 through 19, pan along both axes and return to position following. |
| GRID04 | Display a filtered position marker and a bounded trail with at most 180 points. Keep only three filter samples. |
| GRID05 | Suppress stationary noise, reject isolated spikes and preserve slow walking. A persistent relocation requires consistent fixes. |
| GRID06 | Validate coordinates, timestamp, quality and freshness. Never use a guessed location or default to zero coordinates. |
| GRID07 | Show filtered latitude and longitude by default, with START toggling explicitly labeled raw values. Show six decimals, quality and age without internet. Precision must not be presented as accuracy. |
| GRID08 | Show elapsed time, estimated distance, GPS speed and derived pace. Missing or stale movement data must be unavailable. |
| GRID09 | Pause freezes the session clock and disables GPS and the timer. Resume continues with a gap. End and exit clear session data. |
| GRID10 | System inactivity releases subscriptions. Foreground resumes only an active session; never invent distance across a gap. |
| GRID11 | All visible text is English and fits the round display in day and night themes. Physical buttons cover every core action. |
| GRID12 | Diagnostics show version, heap, trace count, GPS count and filter status. No private coordinates, token or URL appears there. |

The three sample median, low speed veto, bounded motion confirmation and smoothing
are display behavior, not a change to the GPS sensor. Fresh still acceleration can
veto GPS motion. Fresh unconfirmed motion also holds position; repeated gait peaks
or multiple recent steps provide movement evidence. Motion assistance
is optional in Diagnostics and uses bounded data only while the session is active.
See [ADR 009](docs/decisions/009-wrist-motion-rejection.md) for thresholds and limits.
Physical GPS drift cannot be guaranteed to disappear. Raw values remain available.

## Privacy and resource requirements

- Only Positioning and Sensor permissions are granted. No Communications, FIT or Background
  permission, activity recorder, phone API, upload task or analytics is allowed.
- No session data, FIT file, preference, trace, map cache or location log is saved.
  Upgrade cleanup may delete only the three known obsolete app preference keys.
- Existing Garmin activities and independent health settings must remain untouched.
- The trace and filter stay bounded. One timer requests redraws once per second.
  GPS callbacks update state without adding another repaint cadence.
- End and exit release coordinates, trace, counters, elapsed time, GPS, motion sensor and timer.
  The executable itself occupies storage; session data must remain in RAM only.
- Keys, tokens, local configuration, real GPS exports, SDKs and build products stay
  outside source control and the source package. Publication checks cover staged
  files and reachable history as well as current source.

## Development and validation

Use `.venv` for Python. Keep the official SDK outside Git and verify APIs against
its installed documentation. Build only for `fr165`. No global package installation,
firmware change, account modification or public deployment is part of routine work.

Run `make test`, `make build-watch` and `make test-watch` when possible. Record exact
artifact identities and distinguish PASS, FAIL and NOT RUN. Synthetic simulator
screenshots must be labeled. A source archive must compile from a fresh extraction.

Tests cover stationary noise, walking, slow movement, unknown speed, spikes,
relocation, weak and stale fixes, GPS gaps, date line and polar limits, zoom/pan,
button paths, session cleanup, repeated start/stop and screen layout. Security
regressions exercise forced staging, staged content that differs from working
files, deleted history secrets, local credentials and archive boundaries.

## Acceptance boundaries

Physical stationary behavior failed in v0.2.1 and remained imperfect in v0.2.2:
the user reported 7 to 11 m drift when the arm moved slightly. Version 0.2.3 requires
stronger movement evidence and has passed physical installation with identical
USB readback. The user confirms stationary position holds and walking advances.
That limited physical check is PASS; quantitative accuracy and battery acceptance
remain unmeasured.
Use the [field checklist](docs/grid-field-test.md). Full G0/G3 remains unpassed.

Keep the original performance targets as historical targets, not measured claims.
In particular, a one second redraw cadence is not proof of the former 500 ms p95
marker target. Any future acceptance target change needs an explicit decision.

No downloaded map, route import, persistent activity, sync, remote portal or native
iOS companion is required by the current scope. Those earlier proposals must not
silently return during maintenance.
