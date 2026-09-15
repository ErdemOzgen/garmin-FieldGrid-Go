# Progress — 15 September 2026

## GitHub publication preparation

The user authorized pushing this project to `ErdemOzgen/garmin-FieldGrid-Go`.
The existing remote main branch contains the Apache 2.0 license. Its initial commit
and license are preserved through a merge with the local project history.
The README now links to that license. Two links to the removed original requirements
document now point to the historical raster overview; current requirements remain
the active specification.

Publication checks passed for working files and reachable history. `make test`
passed all 116 tests, with the two previously documented dependency warnings.
The fr165 production build passed without warnings. The watch source hash still
matches the 37 passing simulator tests, so those unchanged runtime tests were not
repeated for this publication. See [preflight review](evidence/publication/github-preflight.md).

## Wrist movement rejection — v0.2.3

The user reports v0.2.2 still drifts 7 to 11 m with slight arm movement, although
it is improved: physical stationary acceptance FAIL. Two new synthetic regressions
reproduce wrist motion and isolated step increments releasing the held position.

The new classifier uses acceleration magnitude and repeated gait peaks, requires
multiple native steps, and keeps fresh unconfirmed motion in HOLD. Diagnostics
now distinguishes VERIFY, GAIT and STEPS. No permission, sampling frequency, timer,
storage, recording or transmission was added.

**116 Python tests, 37 fr165 tests and zero warning production build PASS.** The
126,620 byte executable was installed on the physical Forerunner 165 and read back
identically. The user confirms the position stays still when stationary and advances
when walking: limited physical standing/walking check PASS. No numerical accuracy
or battery measurement was supplied; full G0/G3 remains unpassed.
See [evidence](evidence/wrist-motion/README.md) and
[ADR 009](decisions/009-wrist-motion-rejection.md). Native screenshots below are
historical; the unchanged layout passes rendering tests in both themes.

## Previous stationary drift correction and sensor support — v0.2.2

The user reports 12 to 34 m stationary drift affecting marker and distance in
v0.2.1: physical stationary behavior FAIL. The baseline now reproduces the defect
with two assertion errors. The corrected filter prevents low speed from being
overridden by displacement and excludes held error when walking resumes.

The user authorized other watch sensors. Added bounded accelerometer stillness
and native step evidence, optional through Diagnostics START. Raw and Filtered
coordinate modes are explicit; Filtered is the default. Only Positioning and Sensor
permissions are granted. No recording, storage writer or transmission is added.

**116 Python tests, 32 fr165 tests and the zero warning production build PASS.**
The 125,260 byte v0.2.2 PRG was installed through OpenMTP and read back identically.
The later user test reports 7 to 11 m drift with slight arm movement: stationary
behavior FAIL. Complete G0/G3 and battery acceptance remain unpassed. Synthetic sensor stress covers 300,000 samples,
20 lifecycle loops and bounded retained heap. The native simulator screens fit;
continuous GPS/sensor replay was not sustained during manual setup and is not
claimed as a PASS. See [evidence](evidence/stationary-filter/README.md) and
[ADR 008](decisions/008-stationary-motion-assist.md).

The publication preparation and v0.2.1 records below describe earlier snapshots.
The current binary differs from the previously installed publication snapshot.

## Publication preparation — 15 September 2026

English documentation and README with six synthetic simulator images are complete.
Prose avoids hyphen compounds; technical identifiers and paths keep their syntax.
The initial requirements now have an English edition with original IDs and targets;
the current requirements are separate. Original documents and 19 historical Turkish
screenshots are retained in ignored private backup. Git history was not rewritten.

Expanded ignore rules cover keys, credential containers, environment variants,
SDKs, caches, build archives and private device exports. The source/index/history
scanner reports paths and categories only. Commit and push hooks are installed for
this clone; CI fetches full history and repeats the checks. Browser uploads must use
the extracted source ZIP because the browser does not apply Git ignore rules.

**116 Python tests (23 publication regressions) and 20 fr165 tests PASS.** Working
files, staged blobs and reachable history passed credential scans. The production
PRG remains identical to the binary installed on the watch. The initial sandboxed
simulator launch failed with macOS -10827; the permitted local retry passed.
README source images and links were checked; browser HTML preview was blocked by
URL policy and is not claimed as a completed browser review. No remote/account,
publication or firmware change was made. See [publication evidence](evidence/publication/result.json)
and [review](evidence/publication/review.md).

## Previous delivery: FieldGrid G0 v0.2.1, local only

The user explicitly chose an offline grid and live information without recording or
transmission. FIT recording and sync were removed. The retention question is resolved.
**Installed on the physical Forerunner 165; USB readback PASS. Grid launch without IQ
error PASS by user report. Physical accuracy/endurance and full G0/G3 remain NOT RUN.**

- WGS84 geographic grid, pan/follow, zoom 10–19, filtered marker and a bounded
  180-point trace. Raw lat/lon page works from the watch GPS without internet.
- Live elapsed time, filtered distance estimate, GPS speed and derived pace.
  No native activity recording, FIT file, phone API, server or network permission.
  Manifest grants only Positioning. No new app data/preferences are persisted.
- START opens the grid; DOWN opens raw coordinates. GPS requires either explicit
  action. BACK from grid pauses; Resume continues; End session clears all session
  data. Exit releases GPS/timer. System interruption releases GPS and resumes an
  active session with a gap; missing distance is never guessed.
- **93 Python tests and 20 fr165 tests PASS; build zero warnings.** English UI
  visually reviewed on round 390×390 with final build synthetic screenshots.
- Stationary 600-fix test: one point, zero distance. Stress covers 30,000 fixes,
  1,000 redraws and 40 GPS start/stop cycles / 12,000 additional fixes. Test heap
  growth after warm up stays within the asserted 512 B bound. Production simulator
  diagnostics snapshot: 25 KiB used/peak. Physical battery is not measured.
- PRG **119,084 B**, SHA-256
  `e3f29827ddae900b2ab56dd6a9f1c9b8671a25351d04624ed8418075b37d8fc1`.
  Copied to `GARMIN/Apps/FieldMap.prg` through OpenMTP 3.3.0 Kalam; retrieved PRG
  matches byte for byte. No prior FieldMap.prg was present. Personal activities
  were neither read nor changed. User subsequently confirmed: "The grid opened without an error (translated user report)".
- Source archive extracted under /tmp: all 93 tests and a clean zero warning fr165
  build PASS, with matching watch source hash and a separate temporary signing key.
- .venv retained; official SDK and OpenMTP only restored under /tmp after checksum
  verification. No global packages, firmware change, public tunnel or account change.
  Sandbox USB query was falsely empty; an escalated read only query confirmed MTP.

See [current evidence](evidence/grid-only/README.md),
[ADR 007](decisions/007-local-only-no-recording.md),
[review](evidence/grid-only/review.md) and [physical checklist](grid-field-test.md).
The [v0.2.0 progress](archive/progress-grid-fit-2026-09-15.md) and raster history below
are historical and do not describe the installed application.

---

# Progress — 14 September 2026

The requested OpenFreeMap, English UI and offline coordinate extension is
implemented. Local tests pass. **Physical G0/G3 acceptance remains NOT RUN.**
The user subsequently requested installation on the connected physical watch.
USB sideload and readback now PASS; this does not pass physical G0 acceptance.

## Current delivery

- Free OpenFreeMap vector data converted to 16-color PNGs by the Python service.
  No upstream API key, account or subscription. Visible attribution and credits.
- English only watch UI, tested with the simulator language set to Turkish.
- Home DOWN starts GPS only mode: WGS84 latitude/longitude, six decimal places,
  fix status and age, zero map requests. No guessed coordinates; `--` before a fix.
  Polar coordinates remain available outside Mercator map coverage.
- Bounded 180-point trace, one active plus one incoming native raster and a
  temporary paletted download during conversion, single network job,
  96 KiB free heap reserve before new downloads. Stop releases session resources.
  Preferences reuse one small key; no saved GPS history or map database.
- Renderer: one non queuing job, 18-second deadline, 64 KiB PNG, 24 output entries;
  compressed vector cache limited to 16 entries AND 8 MiB, with no disk cache.
- Python dependencies updated and locked inside `.venv`; no global installs.

## Observed verification

**89 Python tests PASS, 96% API line coverage; 22 Monkey C tests PASS on `fr165`.**
Final watch build has zero warnings. Dependency audit reports no known
vulnerabilities; two upstream Python deprecation warnings remain.

Accelerated stress: 40 sessions, 15,000 synthetic GPS events and 160 native bitmap
replacements across 195/256/390 px, now including conversion to native color.
Post stop heap stays at 47,384 B; overlap peak is 66,288 B. Logging allocates
another 112 B after the measured sample. This is
application heap in the simulator, not all native graphics memory or a two hour
wall clock/physical battery test.

New English coordinate, no fix, stale fix, recovery, credits, day/night and home
screens were visually checked. Final offline test used BLE Not Connected, no API,
and explicit synthetic GPX: Phone NO, Images 0, GPS counter advancing. Session
was stopped and simulator BLE setting restored afterward.

Real OpenFreeMap data was fetched and rendered locally for all six Utrecht
size/theme profiles, plus Amsterdam and Brussels samples. PNGs range from 8,410
to 35,273 bytes. These are fixed public sample locations, not user GPS traces.
Final loopback HTTP verification also passed all six profiles, including authentication
and 16-color PNG checks; the temporary local API was stopped.
See [provider records](evidence/openfreemap), [simulator record](evidence/simulator.json),
[review](evidence/openfreemap/review.md) and [G0 matrix](evidence/g0.md).

## Remaining boundary

`FR165_PUBLIC_BASE_URL=http://127.0.0.1:8765` names the Mac's own converter.
Garmin needs a reachable HTTPS converter for online maps. Free OpenFreeMap data
does not itself supply that hosting. No permanent service or paid account was created.

The earlier approved synthetic map HTTPS test ended at 19:12:03 UTC after about
22 minutes. Its tunnel/API were stopped and configuration restored. Historical
results are retained in `previous-synthetic-*.json`. The subsequent authorized
physical OpenFreeMap test is recorded below: initial drawing FAIL, corrected
display PASS by user report. Its public tunnel has also been closed.

The user reports physical GPS acquisition and a working real map. Independent GPS
accuracy/age, iPhone background endurance, wrist lifecycle, native graphics memory,
storage capacity/reboot, two hour endurance and battery remain **NOT RUN**.
User/account pairing and GPX/FIT/offline city packages remain later stage scope.

Source package checks and exact artifact hashes are recorded in
[automated evidence](evidence/automated.json) and [source package evidence](evidence/source-package.json).
No GitHub push or Connect IQ Store publication is performed.

## Physical installation follow up

`FieldMap.prg` was copied to the actual Forerunner 165 (part 006-B4432-00,
GarminDevice.xml SoftwareVersion 2905). The 127,196-byte file was downloaded
back from GARMIN/Apps and matched SHA256 byte for byte. Existing watch files were
not overwritten or removed. After a normal watch restart, MTP enumeration worked;
OpenMTP 3.3.0 Kalam completed the transfer. The legacy client did not work.
See [physical installation evidence](evidence/physical-install.json).

The first installed build provided offline GPS and omitted the Mac only URL/token.
The user confirmed it opened, while maps were absent. It was subsequently replaced
by the HTTPS experiment builds described below. No firmware was changed.

## Authorized physical HTTPS experiment

The user subsequently approved a real watch test with a temporary public HTTPS
origin for at most 30 minutes. It started at 20:58:42 UTC; automatic process cleanup
completed at 21:28:43 UTC (1,800.5 seconds). Both ports are closed and private
configuration is restored byte for byte. The earlier installation
paragraph describes the prior offline build, not this temporary test build.

Repeated checks: 89 Python tests and 21 `fr165` tests PASS; the new HTTPS watch
build has zero warnings. Its 127,276-byte PRG was copied to the physical watch
and verified byte for byte by download. HTTPS preflight with fixed public sample
coordinates successfully obtained a real OpenFreeMap PNG. The user then reported
an IQ/exclamation crash after GPS fix. The server had successfully served metadata
and PNGs, but physical map display FAILED. The watch log locates the exception in
the palette backed drawBitmap2 call. Firmware 29.05 / runtime CIQ 6.0.2 are now
confirmed by the physical log (different from the SDK target API profile).

A native color conversion and guarded drawing fix passes 22 fr165 tests and was
installed with byte for byte readback (128,012 B). The user confirms that the map
now appears without crashing; physical map display recovery is PASS by user report.
Full G0/G3, native pool memory, endurance and battery remain unverified;
see [ADR 005](decisions/005-fr165-native-raster.md) for memory tradeoffs. No permanent
hosting or Store publication has been performed. See [physical HTTPS evidence](evidence/physical-https.json).

## Short locked phone test and diagnostic photo

The user confirms that maps refreshed while the iPhone was locked and both UP and
DOWN zoom buttons worked. This short physical check is PASS by user report; the
30-minute continuous background/endurance requirement is still NOT RUN.

A subsequent supplied diagnostic photo shows Phone YES, code -400, heap/peak
27/27 KiB, Images 0, Trace 11, GPS callbacks 44 and Store NOT RUN. Code -400 means
an invalid response body for the requested type. The expired tunnel is a possible
cause, not proven by the photo. No map was loaded in that photographed session, so
the 27 KiB figure cannot establish map loaded heap, native graphics memory or
long term stability. The original photograph remains private.

## Compact map attribution

The requested smaller source credit uses one 18 px native font line in a
225 x 24 px band (previously 270 x 63 px). No font file or map cache was added.
Both map themes and the complete credits screen fit in the fr165 simulator.
89 Python and 22 watch tests pass; physical target build has zero warnings.
[Current compact attribution evidence](evidence/compact-attribution/result.json)
contains current source/artifact identities; older automated/package records
are historical. The compact UI build has not been installed on the watch.
