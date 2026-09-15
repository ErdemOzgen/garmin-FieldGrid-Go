# ADR 004 — Free map provider, English UI, offline coordinates

14 September 2026. User authorized extension of the G0 prototype; physical G0/G3
acceptance remains NOT RUN. This supersedes the synthetic only product restriction
for the requested provider integration, not the physical acceptance gate.

OpenFreeMap's public service explicitly has no API key, registration or request/view
quota. It has no SLA and does not provide PNG/static map generation. We use its
OpenMapTiles vector data through a small Python raster converter. The watch receives
only a 195/256/390 px, 16-color PNG; no vector database or map package is installed
on the watch. Service user agent identifies FieldMap. Attribution is visible on the
watch and in Map credits. No street names or paths are invented.

`FR165_MAP_PROVIDER=openfreemap` selects real maps; `synthetic` is an explicit test
option. Provider failure returns a bounded, retryable 503 and never substitutes a
synthetic image. `FR165_PUBLIC_BASE_URL` is the reachable origin of OUR raster
converter, not the provider URL. `http://127.0.0.1:8765` is local Mac development.
Garmin image conversion requires a public HTTPS origin for the final PNG. The
OpenFreeMap provider has no token; `FR165_DEV_TOKEN` protects the user's own service
from uninvited renders and is not a paid map subscription or upstream credential.
The service's 30 renders/minute is a configurable local abuse/resource guard, not
an OpenFreeMap account quota. Normal watch requests start at most every 5 seconds.

Alternatives examined: OSM's standard public raster tiles impose user agent,
caching and no prefetch requirements; they are not an unlimited raster backend.
OpenFreeMap vectors keep the requested free/no key provider, at the cost of a small
HTTPS renderer. A full MapLibre/Node/GPU stack would add considerable deployment
weight. Our Pillow style covers water, parks, buildings, roads/paths and compact
English/local labels; it is not pixel identical to OpenFreeMap Liberty.

Resource limits: maximum 9 viewport intersecting z14 tiles (overzoom for z15/16),
1 MiB received bytes per tile, 16 cached compressed tiles AND 8 MiB cache bytes,
24-hour in memory TTL, one decoded tile at a time, 30k features / 300k drawn points
per tile, 18-second render deadline, 64 KiB PNG ceiling. One renderer works at a
time; surplus requests get retryable 503 instead of an unbounded queue. Existing
PNG reads use a separate short lock and continue during slow upstream work. No
disk tile cache exists. PNG grants remain 120 seconds, max 24 cached images.

The watch always uses English (including when simulator language is Turkish).
Home DOWN explicitly starts GPS only mode: zero map requests, coordinates and age
available without phone/internet. Six decimal digits are display precision, not a
claim of sub meter GPS accuracy. No fix displays `--`; lost quality displays last
known coordinates and age. Geographic GPS coordinates support +/-90 degrees;
Mercator maps remain limited to +/-85.0511288 degrees. No guessed coordinates.

RAM: 180-point trace; one active image and at most one incoming image. A 16-color
conversion palette bounds raster size. Before a new map job, at least 96 KiB free
heap is required; low memory deferral leaves GPS active. Stop cancels subscriptions,
timer/network and releases map and trace. Preferences reuse one small key and only
write when values change. No GPS history is persisted. Stress tests distinguish
accelerated two hour event streams from two hour wall clock or physical testing.

Sources checked 14 September 2026:
- [OpenFreeMap service and attribution](https://openfreemap.org/)
- [OpenFreeMap limitations](https://github.com/hyperknot/openfreemap#limitations-of-this-project)
- [Integration guide](https://openfreemap.org/quick_start/)
- [OSM raster tile policy](https://operations.osmfoundation.org/policies/tiles/)
- [Vector decoding library](https://github.com/tilezen/mapbox-vector-tile)
- Installed SDK 9.2.0: Communications.makeImageRequest palette, System.Stats freeMemory,
  Position.Info and Application.Storage. Compiled only for `fr165`.
