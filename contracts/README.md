# Historical G0 raster protocol

These contracts belong to the earlier raster service, not the current offline watch
app. `make contracts` generates `openapi.json` from the Pydantic models. Examples
use synthetic 52°N / 5°E coordinates, never the user's location.

`POST /v1/map-renders` includes schema version, request generation, coordinates,
zoom, size and style. Images contain no position marker or personal trail. Bounds
represent pixel edges in EPSG:3857 meters: `[minX, minY, maxX, maxY]`. All three
raster sizes cover the same geographic area at 390 screen pixels. The upper left
edge is `(minX, maxY)`; pixel centers sit half a pixel inside.

Metadata returns `renderId` and an `imageUrl` valid for two minutes. A signature for
another render cannot fetch the image. HTTP tests verify `X-Render-Id`. Garmin image
callbacks expose no headers, so the former watch checked the validated URL,
generation, pending metadata and dimensions before atomic activation.

Client errors and 429 responses provide `code`, `retryable`, `retryAfterSec` and
`requestId`, without reflecting input values. Default loopback service requires no
token; `make dev-config` enables one locally. A remote HTTPS origin requires a token.
The device token is not placed in the URL. Pairing, configuration, route and device
removal endpoints were later proposals; no fake success stubs were added.
