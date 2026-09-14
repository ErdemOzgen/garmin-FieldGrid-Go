# OpenFreeMap and offline position review

## Critical findings

None verified after corrections. Physical acceptance and a permanent reachable
renderer are still missing; they are not inferred from local success.

## Important findings

- No direct public PNG endpoint exists at OpenFreeMap. The integration requires
  our HTTPS raster converter. README now distinguishes free map data from renderer
  hosting; localhost and a provider's website are not interchangeable origins.
- API rendering previously held the image-cache lock. With real external I/O,
  this would block PNG downloads behind a slow provider. Rendering now has a
  separate non-queuing slot; concurrent jobs receive retryable 503. A blocked-
  provider test proves existing PNG reads still complete.
- Cache eviction initially subtracted the size of a tuple rather than tile bytes.
  The regression exposed the accounting error. Both entry and byte budgets are
  now tested, including eviction at 8 MB before the 16-entry limit.
- A GPS-only session must not merely tolerate a failed API: it must send zero map
  requests. Home DOWN sets networkEnabled=false; unit tests assert requestCount=0
  after valid fixes. UI was checked with no API running and BLE Not Connected: live coordinates, Phone NO, Images 0.
- A real map must not silently become a test grid during a provider error.
  The API returns sanitized 503; the watch retains its old geographically bound
  image and GPS. Synthetic mode is explicitly selected and visibly labeled.

## Minor findings

- Two new English status labels exceeded the round screen's safe width; shortened
  and covered by measured font-width checks. Coordinates and map credits were
  visually inspected in the simulator.
- Palette integers must be converted to RGB tuples for Pillow; otherwise red and
  blue channels swap. Palette membership regression and real-map preview verify it.
- Some dense z14 vector tiles may exceed the deliberate 1 MiB limit. Such views
  return an explicit service error; no guarantee of every place's coverage is made.
  Provider/cache/geometry limits protect the renderer, with possible availability
  trade-offs on unusually complex views.
- The simplified renderer does not implement every MapLibre style detail. Road
  name collision checks are bounded; label density at 195 px is reduced by size.

## Open questions

Public HTTPS simulator test for these new real maps requires separate time-limited
approval. Actual iPhone/GCM, firmware, wrist lifecycle, physical RAM/graphics and
battery still require hardware. OpenFreeMap offers no SLA. A free provider does
not provision an always-on converter server automatically.

## Recommended corrections

Applied: English-only resources; offline WGS84 coordinates including polar fixes;
no stale-fix promotion; bounded trace, immutable provider framing, compressed
cache limits, non-queuing render slot, HTTPS origin allowlist, expiry after render
completion, 16-color watch palette and pre-request memory reserve; deduplicated
preference writes. No GPS history or map database is persisted on the watch.

Validation: 89 Python tests at 96% API line coverage, 21 fr165 tests including
40 sessions / 15,000 GPS events / 160 native bitmap replacements across three
sizes. Bitmap-overlap application heap peak 63,576 B in the recorded run; steady
post-stop sample 45,064 B. Logging itself allocated 112 B after that sample.
This is accelerated simulator evidence, not physical two-hour endurance or a
measurement of all native graphics memory. Dependency audit reported no known
vulnerabilities after the lock update. Detailed command output accompanies this file.

Final package verification: source ZIP extracted without private configuration/keys;
89 Python tests and a fresh fr165 build passed using the existing isolated .venv.
Final real loopback HTTP smoke: all six OpenFreeMap profiles PASS, 16 colors maximum,
401 without renderer authorization, API stopped afterward. This is not Garmin HTTPS.
