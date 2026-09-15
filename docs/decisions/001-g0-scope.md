# ADR 001 — G0 scope and toolchain target

Accepted local implementation decision, 14 September 2026. Historical raster
architecture; [ADR 007](007-local-only-no-recording.md) defines the current scope.

The original specification required physical GPS, raster and iPhone evidence
before advancing beyond G0. A local simulator pass could not pass that gate.
The initial delivery excluded a large portal, production account pairing, GPX
processing, FIT recording and offline map packages.

One Monkey C Watch App and one FastAPI process were selected. Starting with a full
vector engine or a custom iOS app would add cost before device capability was
measured. The raster adapter stayed small and replaceable. Python used `.venv`.

SDK Manager's Forerunner 165 package reports `deviceId=fr165`, 390 × 390 pixels,
API 5.2 and a Watch App limit of 786432 bytes. The original `forerunner165` name is
not the CLI identifier; all builds use `fr165`, never a substitute model.
The device package's `firmwareVersion` is not a measurement of the user's watch.

SDK 9.2.0 and the device package are pinned in `toolchain.lock.json`. The archive
`2026-06-09-92a1605b2`, its SHA256 and actual tool output identify the installation;
dates in the SDK catalogue and download page can differ.

The simulator lacked `drawScaledBitmap` on this target. The raster prototype used
`drawBitmap2` with `AffineTransform`, requiring minimum API 4.2.1. This minimum is
separate from the device's API 5.2 support. Rendering and fonts were tested locally.
The later physical bitmap correction is recorded in ADR 005.

Provider processing, resizing, cache, attribution and cost rights required a separate
decision. Standard OSM tiles were not automatically requested or downloaded in bulk.

References: [Garmin SDK](https://developer.garmin.com/connect-iq/sdk/),
[Graphics Dc](https://developer.garmin.com/connect-iq/api-docs/Toybox/Graphics/Dc.html),
[Communications](https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html).
API names were also checked against installed SDK documentation and the simulator.
