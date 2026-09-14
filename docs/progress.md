# Progress — 14 September 2026

The requested OpenFreeMap, English UI and offline coordinate extension is
implemented. Local tests pass. **Physical G0/G3 acceptance remains NOT RUN.**
The user's simulator-only instruction remains in effect.

## Current delivery

- Free OpenFreeMap vector data converted to 16-color PNGs by the Python service.
  No upstream API key, account or subscription. Visible attribution and credits.
- English-only watch UI, tested with the simulator language set to Turkish.
- Home DOWN starts GPS-only mode: WGS84 latitude/longitude, six decimal places,
  fix status and age, zero map requests. No guessed coordinates; `--` before a fix.
  Polar coordinates remain available outside Mercator map coverage.
- Bounded 180-point trace, one active plus one incoming raster, single network job,
  96 KiB free-heap reserve before new downloads. Stop releases session resources.
  Preferences reuse one small key; no saved GPS history or map database.
- Renderer: one non-queuing job, 18-second deadline, 64 KiB PNG, 24 output entries;
  compressed vector cache limited to 16 entries AND 8 MiB, with no disk cache.
- Python dependencies updated and locked inside `.venv`; no global installs.

## Observed verification

**89 Python tests PASS, 96% API line coverage; 21 Monkey C tests PASS on `fr165`.**
Final watch build has zero warnings. Dependency audit reports no known
vulnerabilities; two upstream Python deprecation warnings remain.

Accelerated stress: 40 sessions, 15,000 synthetic GPS events and 160 native bitmap
replacements across 195/256/390 px. Post-stop heap stays at 45,064 B; overlap peak
is 63,576 B. Logging allocates another 112 B after the measured sample. This is
application heap in the simulator, not all native graphics memory or a two-hour
wall-clock/physical battery test.

New English coordinate, no-fix, stale-fix, recovery, credits, day/night and home
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

The earlier approved synthetic-map HTTPS test ended at 19:12:03 UTC after about
22 minutes. Its tunnel/API were stopped and configuration restored. Historical
results are retained in `previous-synthetic-*.json`. They do not prove the new
OpenFreeMap images passed through Garmin. A new time-limited HTTPS test was
requested; absent renewed approval, that new end-to-end check is **NOT RUN**.

Physical GPS, iPhone/GCM/background connectivity, wrist lifecycle, native graphics
memory, storage capacity/reboot, two-hour endurance and battery remain **NOT RUN**.
User/account pairing and GPX/FIT/offline city packages remain later-stage scope.

Source package checks and exact artifact hashes are recorded in
[automated evidence](evidence/automated.json) and [source-package evidence](evidence/source-package.json).
No GitHub push or Connect IQ Store publication is performed.
