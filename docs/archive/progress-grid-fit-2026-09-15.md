> Historical v0.2.0 progress. Superseded by ADR 007 and the current docs/progress.md.

# Progress — 15 September 2026

## Current scope: FieldGrid v0.2.0

The user replaced raster maps with an entirely offline WGS84 grid and requested
filtered GPS, live activity information and Garmin Connect FIT activity recording.
Implementation is complete locally; **physical grid/FIT G0/G3 is NOT RUN**.
The later request to delete activities automatically after sync requires a retention
decision: Connect IQ has no completed sync/saved FIT delete API. The user has been
asked whether to keep FIT with manual deletion or remove persistent activity recording.
**No new watch deployment until this is resolved.** This is a platform constraint,
not a request for routine implementation permission.

- Real GPS north up geographic grid, pan/follow and zoom 10–19; no network permission,
  service, map bitmap, token or phone needed. Raw lat/lon six decimals with quality/age.
- Median + hold/smoothing filter, gap aware 180-point ring; no stationary timer only
  points, no inferred bridge across lost GPS. Filter does not modify Garmin FIT.
- Native Walk/Run/Hike/Bike recording, native activity time/distance/speed, pace and HR
  when available. Pause/Resume/Save/confirmed Discard; retain handle on failure.
- No new app storage writes. Zoom/theme/sport only in RAM; three known old app keys
  are removed on upgrade. Grid/trace is released when ending a session. FIT files
  are the explicit native recording exception; they are not deleted after sync.
- Source ZIP was extracted into a clean temporary checkout: 92 tests and a new
  zero warning fr165 build PASS, with identical watch source hash and a separately
  generated local signing key. No private configuration/dependencies were packaged.
- **92 Python tests and 23 fr165 tests PASS; physical target build zero warnings.**
  30,000 GPS samples / 30 trace sessions; 1,000 redraws; 12,000 samples / 40 actual
  simulator GPS subscription start/stop cycles. No post warm up growth beyond the
  asserted 512 B lifecycle bound. Detailed values and caveats in current evidence.
- English screens checked on round 390×390 fr165. Fresh grid day/night, coordinate,
  stats and diagnostics captures use synthetic simulator data. App PRG is 124,668 B.
- Python uses .venv. Official SDK restored only under /tmp with locked SHA-256;
  no base Python install, firmware change, public tunnel or account change.

See [current evidence](../evidence/grid/README.md), [ADR 006](../decisions/006-offline-grid-and-fit.md),
[review](../evidence/grid/review.md) and [physical checklist](../grid-field-test.md).
Earlier raster progress below is historical and does not describe the current app.

---
