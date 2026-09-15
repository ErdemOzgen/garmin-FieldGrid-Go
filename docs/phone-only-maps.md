# Map access without the Mac

Assessment, 14 September 2026. No provider account, deployment or new public
tunnel has been created. The user requested an alternative using only the iPhone.

The existing iPhone/Garmin Connect bridge works: the user confirmed map refresh
with the phone locked. The renderer's explicitly limited test tunnel closed at
21:28:43 UTC. Its expired origin remains in the installed test build. The photo
shows Phone YES and -400 (invalid response body); it does not prove a Bluetooth
failure or the exact response that caused that code.

## Direct raster tiles through Garmin Connect

A watch can request an existing HTTPS PNG with makeImageRequest. This would remove
our Python renderer, Mac and tunnel, while retaining Garmin's network/image bridge.
It requires a tile based watch downloader; changing the current base URL alone is
insufficient because the current protocol requests render metadata first.

The candidate implementation would compute z/x/y tile bounds locally, download
only the current viewport sequentially, convert to the already verified native
color format, and commit a completed composite with its camera metadata atomically.
It must retain the last complete map and GPS during failures, reject obsolete
responses and bound bitmap/cache/request counts. No city downloads or unbounded
tile storage. Provider attribution and secret handling must change with the mode.

**Stadia Maps is a feasible candidate, not a tested integration.** Its current free
plan covers personal/non commercial use, has 200,000 credits/month, charges one
credit per standard raster tile, and permits no additional free plan usage. A free
account/API key is required outside browser based use; no credit card is needed.
Only standard raster tiles qualify here: the separate static map API is outside
the free tier. A key used in a Garmin image URL would be visible to Garmin's image
bridge as well as Stadia, and must stay out of Git, logs and shared screenshots.
Quota exhaustion should preserve GPS and the previous map, not trigger upgrades.

Before selecting this mode, resolve the user's no key/no quota preference. Before
any account action, obtain explicit authorization. Verify an authenticated fixed
sample through the FR165 simulator and then the physical iPhone/watch path. Until
then the current app remains the OpenFreeMap renderer version.

## Why the keyless alternatives are not drop in replacements

- OpenFreeMap supplies vector data. Its mobile integration uses MapLibre Native;
  Garmin Connect does not execute our Pillow/MapLibre renderer for us.
- OSM standard raster tiles require app identification and HTTP aware caching
  (or a minimum seven day cache). The installed makeImageRequest API has no
  documented custom header or response header interface. End to end compliance
  through Garmin's image proxy is unverified; do not assume unlimited permission
  or quietly route production traffic there.
- OSM France also requires identifiable mobile app requests and moderate traffic.
- CARTO now requires a free API key; its PNG raster service is being retired.
  It is therefore not the preferred basis for a new raster implementation.

## Companion iPhone application

An iOS app could render OpenFreeMap data locally and exchange bounded chunks with
the watch using the Garmin Mobile SDK. This needs a new rendering/transfer protocol,
iOS signing/installation, and physical testing of delivery and memory limits.
Ordinary iOS background execution is limited; phone lock behavior cannot be
promised without validating an appropriate supported lifecycle. It is a larger
and less proven change than direct hosted PNG tiles.

A stable hosted copy of the current renderer is the least watch code change, but
needs an explicitly selected service/account. Free hosting tiers are not the same
as unlimited always on operation. No such hosting has been selected or published.

## Primary sources checked

- [Garmin Communications API](https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html)
  and installed SDK 9.2.0 documentation.
- [OpenFreeMap limitations](https://github.com/hyperknot/openfreemap#limitations-of-this-project)
  and [mobile integration](https://openfreemap.org/quick_start/).
- [OSM tile policy](https://operations.osmfoundation.org/policies/tiles/).
- [OSM France usage policy](https://www.openstreetmap.fr/usage/).
- [Stadia free plan and credit schedule](https://stadiamaps.com/pricing),
  [authentication](https://docs.stadiamaps.com/authentication/) and
  [limits](https://docs.stadiamaps.com/limits/).
- [CARTO key requirement and raster retirement](https://carto.com/basemaps/apikey/).
- [Garmin Mobile SDK messaging](https://developer.garmin.com/connect-iq/connect-iq-faq/how-do-i-use-the-connect-iq-mobile-sdk/).
- [Apple background execution](https://developer.apple.com/documentation/uikit/extending-your-app-s-background-execution-time).
