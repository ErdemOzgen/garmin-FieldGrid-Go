<div align="center">

# FieldGrid

### Your position. A simple grid. Nothing uploaded.

An offline GPS companion for **Garmin Forerunner 165**.

**English interface · Live coordinates · Bounded memory · No account**

<img src="docs/evidence/grid-only/synthetic-grid-day.png" width="250" alt="Day grid with geographic coordinate lines and a filtered position marker">
<img src="docs/evidence/grid-only/synthetic-grid-night.png" width="250" alt="Night grid with the current position and a short breadcrumb trail">
<img src="docs/evidence/grid-only/synthetic-stats.png" width="250" alt="Live elapsed time, distance, GPS speed and pace">

*Screenshots are from the Forerunner 165 simulator. All shown locations and movement are synthetic test data. Grid and stats images show the unchanged v0.2.1 layout; coordinates and diagnostics below show v0.2.2. Coordinate screenshots show the waiting state.*

</div>

## What it does

FieldGrid turns the watch GPS into a geographic grid you can explore while walking.
See your position, a recent trail and live movement information without downloading
maps or connecting your phone. The grid contains coordinate lines, not roads or terrain.

| Feature | Experience |
| :--- | :--- |
| Geographic grid | North up view, WGS84 coordinate labels and a scale in meters |
| Position and trail | Filtered position marker with up to 180 recent trace points |
| Explore the area | Zoom from level 10 to 19, pan both axes and return to your position |
| Coordinates | Filtered latitude and longitude, with a labeled raw view on START |
| Motion assistance | Accelerometer stillness and Garmin step evidence support the GPS filter |
| Live information | Elapsed time, estimated distance, GPS speed and pace |
| Day and night | Two clear themes designed for the round 390 × 390 display |
| Session control | Start, pause, resume and end; nothing is saved or shared |

## Start a session

1. Open **FieldGrid G0** on the watch.
2. Press **START** to open the grid, or **DOWN** for coordinates.
3. Wait outdoors for a usable GPS fix. The app never invents a location.
4. Press **START** from the grid to open live stats, coordinates and other options.
5. Press **BACK** from the grid to pause. Select **End session** to clear the session.

Opening the home screen does not start GPS. No iPhone, Garmin Connect, internet,
API token or server is needed. This app creates no Garmin Connect activity.

<div align="center">
<img src="docs/evidence/grid-only/synthetic-home.png" width="240" alt="Home screen explaining that nothing is saved or shared">
<img src="docs/evidence/grid-only/synthetic-paused.png" width="240" alt="Paused session offering Resume or End session">
<img src="docs/evidence/stationary-filter/synthetic-diagnostics-on.png" width="240" alt="Version 0.2.2 diagnostics with local motion assistance and network and storage disabled">
</div>

<div align="center">
<img src="docs/evidence/stationary-filter/synthetic-coordinates-filtered.png" width="240" alt="Filtered WGS84 coordinates with a clearly labeled raw toggle">
<img src="docs/evidence/stationary-filter/synthetic-coordinates-raw.png" width="240" alt="Raw GPS coordinates with a clearly labeled filtered toggle">
</div>

## Controls

| Screen | Button | Action |
| :--- | :--- | :--- |
| Home | START / DOWN | Start the grid / coordinates |
| Home | BACK | Exit |
| Grid | UP / DOWN | Zoom in / out |
| Grid | START | Open the menu |
| Grid | BACK | Pause the session |
| Menu | UP / DOWN, then START | Choose an option |
| Browse grid | UP / DOWN | Pan along the selected axis |
| Browse grid | START / BACK | Change axis / follow your position |
| Coordinates | START | Toggle Filtered / Raw |
| Diagnostics | START | Toggle motion assistance for this session |
| Stats, coordinates, diagnostics | BACK | Return to the grid |
| Paused session | UP / DOWN, then START | Resume or end the session |
| Paused session | BACK | Resume |

## Privacy and resource use

**Session information stays in watch memory.** The application has only
Positioning and Sensor permissions. It has no network calls, phone integration, activity
recorder, saved FIT files, persistent trace, map cache or analytics.

The display trail holds at most **180 points**, and the position filter holds
**three samples** plus fixed summary anchors. Motion input uses one second batches
of 25 accelerometer samples per axis, discarded after calculating scalar summaries.
One timer updates the display once per second. The v0.2.3 executable is
**126,620 bytes**, about **124 KiB**. Ending the session or exiting stops GPS, motion
sampling and the timer, then releases the session data.

Garmin's separate health and activity features keep their own behavior. FieldGrid
does not change those settings or delete existing activities. The app executable
itself occupies storage; the privacy promise concerns session data.

Fresh stillness or unconfirmed wrist movement holds the marker even if GPS reports
movement. Repeated gait peaks or multiple native steps provide movement evidence;
no daily total is saved or uploaded. Diagnostics shows STILL or VERIFY while holding,
GAIT or STEPS for confirmed evidence, and WAIT, UNAVAILABLE or OFF for GPS fallback. START toggles this
assistance. Disable it if a steady wrist causes legitimate motion to be suppressed.
Missing sensor data falls back to GPS filtering. This is a custom display filter,
not Garmin's native activity algorithm.

The filter reduces stationary jitter and rejects isolated jumps. Slow movement can
appear after a short delay, and sustained GPS drift can still resemble movement.
Distance is a filtered estimate, not Garmin's native activity distance. Six decimal
places describe display precision, not guaranteed GPS accuracy. Weak or stale fixes
are labeled. Raw coordinates remain available beyond the grid's Mercator latitude
limit of approximately ±85.05113°.

If the system hides the app, GPS, motion sampling and the timer stop. An active session resumes when
the app returns to the foreground, with a gap in the trail. Elapsed time can continue
during that interruption; missing movement is never estimated.

## Build locally

Requirements: **Python 3.12–3.14**, **Java 11 or later**, **Garmin SDK 9.2.0**, and
its **Forerunner 165** device package. The verified build target is `fr165`.

```sh
make setup
make install-hooks
make doctor
make test
make build-watch
make test-watch
make sim
```

Python dependencies install only inside `.venv`. SDK files remain outside this
repository. The first build creates a private signing key under `.local/keys`;
existing keys are preserved. See [setup instructions](docs/setup.md) for paths and
simulator details. Simulator GPS data must be explicitly enabled for testing.

To install, copy `build/FieldMap.prg` to the watch's `GARMIN/Apps` folder using MTP.
Disconnect the cable and open **FieldGrid G0**. The filename and app identifier are
retained from FieldMap so upgrades replace the earlier application. This is a local
installation; the app has not been published in the Connect IQ Store.

## Verification

| Check | Result |
| :--- | :--- |
| Python tests, including publication guards | 116 passed |
| Monkey C tests on the `fr165` simulator | 37 passed |
| Production build | Zero warnings |
| Previous physical tests | v0.2.1 and v0.2.2 stationary drift failed by user report |
| Current v0.2.3 physical test | USB readback PASS; stationary hold and walking response PASS by user report |
| English layout | Reviewed on the native 390 × 390 simulator display |
| Long duration physical battery and GPS accuracy | Not yet measured |

Memory tests cover **30,000 synthetic fixes**, **1,000 redraws**, and **40 GPS start
and stop cycles** with another **12,000 fixes**. The production simulator diagnostics
snapshot for the previous v0.2.1 build showed **25 KiB** used memory. Sensor tests
add **300,000 synthetic acceleration samples** and **20 sensor lifecycle loops**,
with no progressive retained heap growth beyond the 512 byte assertion bound. Simulator measurements do not establish
physical battery life. This remains a **G0 prototype**, with full physical acceptance
still pending. See the [latest evidence](docs/evidence/wrist-motion/README.md) and
[field checklist](docs/grid-field-test.md).


## Repository guide

| Path | Purpose |
| :--- | :--- |
| `apps/watch/` | Monkey C application, resources and tests |
| `scripts/` | Build, validation, packaging and publication checks |
| `tests/` | Python tests and synthetic fixtures |
| `docs/decisions/` | Architecture and scope decisions |
| `docs/evidence/` | Measured results with explicit test boundaries |
| `docs/archive/` | Historical map experiments |
| `services/`, `contracts/`, `web/` | Earlier raster experiment, unused by FieldGrid |

The legacy renderer is retained for reference. `FR165_PUBLIC_BASE_URL`, `.env`,
`make api` and `make dev-config` apply only to that experiment. Current watch builds
and simulator runs start no service and read no map credentials.

[Current requirements](requirements.md) · [Latest decision](docs/decisions/009-wrist-motion-rejection.md) · [Progress](docs/progress.md)

FieldGrid is an independent project and is not an official Garmin application.

Licensed under the [Apache License 2.0](LICENSE).
