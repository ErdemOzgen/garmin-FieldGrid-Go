import io
import threading

import httpx
import mapbox_vector_tile
import pytest
from fastapi.testclient import TestClient
from PIL import Image

from services.api.geo import bounds
from services.api.main import Settings, create_app
from services.api.models import RenderRequest
from services.api.openfreemap import (
    ATTRIBUTION,
    DAY,
    MAX_CACHE_BYTES,
    MAX_CACHE_ENTRIES,
    TILEJSON,
    OpenFreeMap,
    ProviderError,
    screen_point,
    tiles_for,
)

TEMPLATE = "https://tiles.openfreemap.org/planet/test-v1/{z}/{x}/{y}.pbf"
REQUEST = dict(schemaVersion=1, requestGeneration=1, latDeg=52.0907, lonDeg=5.1214, zoom=16)


def fixture_tile():
    # Made-up geometry only: color/order/hole/label checks must not need the network.
    return mapbox_vector_tile.encode(
        [
            {
                "name": "water",
                "features": [
                    {"geometry": "POLYGON ((0 0,4096 0,4096 4096,0 4096,0 0))", "properties": {}}
                ],
            },
            {
                "name": "transportation",
                "features": [
                    {"geometry": "LINESTRING (0 2048,4096 2048)", "properties": {"class": "path"}}
                ],
            },
            {
                "name": "place",
                "features": [
                    {"geometry": "POINT (2048 2200)", "properties": {"name:en": "Test Park"}}
                ],
            },
        ],
        default_options={"y_coord_down": True},
    )


def provider_for(handler=None, clock=lambda: 0):
    calls = []

    def respond(request):
        calls.append(str(request.url))
        if handler:
            return handler(request)
        if str(request.url) == TILEJSON:
            return httpx.Response(200, json={"tiles": [TEMPLATE], "maxzoom": 14})
        return httpx.Response(200, content=fixture_tile())

    return OpenFreeMap(httpx.Client(transport=httpx.MockTransport(respond)), clock), calls


@pytest.mark.parametrize("size", [195, 256, 390])
@pytest.mark.parametrize("style", ["day", "night"])
def test_profiles_and_cache_are_bounded(size, style):
    p, calls = provider_for()
    request = RenderRequest(**REQUEST, imageSize=size, style=style)
    data, box, version, attribution = p.render(request)
    im = Image.open(io.BytesIO(data))
    assert im.size == (size, size) and len(data) < 65536 and len(im.getcolors()) <= 16
    assert box == bounds(request.latDeg, request.lonDeg, request.zoom)
    assert version == "openfreemap-test-v1" and attribution == ATTRIBUTION
    count = len(calls)
    assert p.render(request)[0] == data
    assert len(calls) == count
    assert len(p.cache) <= MAX_CACHE_ENTRIES and p.cache_bytes <= MAX_CACHE_BYTES
    p.close()
    assert not p.cache and p.cache_bytes == 0


def test_palette_keeps_rgb_channel_order():
    p, _ = provider_for()
    im = Image.open(io.BytesIO(p.render(RenderRequest(**REQUEST))[0])).convert("RGB")
    palette = {((c >> 16) & 255, (c >> 8) & 255, c & 255) for c in DAY}
    assert set(im.get_flattened_data()) <= palette
    assert ((DAY[3] >> 16) & 255, (DAY[3] >> 8) & 255, DAY[3] & 255) in set(im.get_flattened_data())


@pytest.mark.parametrize("lat,lon", [(0, 0), (52, 5), (85.05, 179.999), (-85.05, -179.999)])
@pytest.mark.parametrize("z", [14, 15, 16])
def test_viewport_tiles_and_edge_alignment(lat, lon, z):
    b = bounds(lat, lon, z)
    tiles = tiles_for(b)
    assert 1 <= len(tiles) <= 9 and all(0 <= y < 2**14 for x, y in tiles)
    x, y = tiles[0]
    a = screen_point([4096, 0], x, y, 4096, b, 390)
    c = screen_point([0, 0], x + 1, y, 4096, b, 390)
    assert a == pytest.approx(c, abs=1e-7)


@pytest.mark.parametrize(
    "body",
    [
        {},
        {"tiles": ["http://127.0.0.1/private"], "maxzoom": 14},
        {"tiles": ["https://evil.example/{z}/{x}/{y}.pbf"], "maxzoom": 14},
        {"tiles": [TEMPLATE], "maxzoom": 13},
    ],
)
def test_bad_tilejson_cannot_redirect_to_another_origin(body):
    p, _ = provider_for(lambda r: httpx.Response(200, json=body))
    with pytest.raises(ProviderError):
        p.render(RenderRequest(**REQUEST))


def test_network_failure_and_oversized_data_are_sanitized():
    for response in [httpx.Response(503), httpx.Response(200, content=b"x" * 32769)]:
        p, _ = provider_for(lambda r, value=response: value)
        with pytest.raises(ProviderError) as error:
            p.render(RenderRequest(**REQUEST))
        assert "https://" not in str(error.value)


def test_bad_protobuf_fails_without_synthetic_fallback():
    def respond(r):
        return (
            httpx.Response(200, json={"tiles": [TEMPLATE], "maxzoom": 14})
            if str(r.url) == TILEJSON
            else httpx.Response(200, content=b"bad protobuf")
        )

    p, _ = provider_for(respond)
    with pytest.raises(ProviderError):
        p.render(RenderRequest(**REQUEST))


def test_cache_eviction_expiry_and_provider_update():
    now = [0]
    p, calls = provider_for(clock=lambda: now[0])
    p.configure(20)
    for i in range(30):
        p.tile_bytes(i, 100, 20)
    assert len(p.cache) == 16 and p.cache_bytes == sum(len(v[1]) for v in p.cache.values())
    count = len(calls)
    now[0] = 86401
    p.tile_bytes(29, 100, 86420)
    assert len(calls) == count + 1
    p.template = "old"
    p.configure(86420)
    assert not p.cache and p.cache_bytes == 0


def test_deadline_is_enforced():
    now = [0]
    p, _ = provider_for(clock=lambda: now[0])
    now[0] = 50
    with pytest.raises(ProviderError):
        p.fetch(TILEJSON, 32768, 40)


def test_provider_error_api_does_not_echo_coordinates_and_releases_slot():
    class Broken:
        def render(self, _request):
            raise ProviderError("private coordinates never exposed")

        def close(self):
            pass

    with TestClient(create_app(Settings(provider="openfreemap"), provider=Broken())) as client:
        for _ in range(2):
            r = client.post("/v1/map-renders", json=REQUEST)
            assert r.status_code == 503 and r.json()["code"] == "MAP_PROVIDER_UNAVAILABLE"
            assert "coordinates" not in r.text and "52.09" not in r.text


def test_slow_provider_does_not_queue_jobs_or_block_existing_png():
    entered, release = threading.Event(), threading.Event()
    from services.api.renderer import render

    class Slow:
        count = 0

        def render(self, request):
            self.count += 1
            if self.count == 2:
                entered.set()
                assert release.wait(5)
            png, box = render(request)
            return png, box, "openfreemap-test-v1", ATTRIBUTION

        def close(self):
            pass

    with TestClient(create_app(Settings(provider="openfreemap"), provider=Slow())) as client:
        first = client.post("/v1/map-renders", json=REQUEST).json()
        result = []
        thread = threading.Thread(
            target=lambda: result.append(client.post("/v1/map-renders", json=REQUEST))
        )
        thread.start()
        try:
            assert entered.wait(5)
            busy = client.post("/v1/map-renders", json=REQUEST)
            assert busy.status_code == 503 and busy.json()["code"] == "RENDER_BUSY"
            assert client.get(first["imageUrl"]).status_code == 200
        finally:
            release.set()
            thread.join(5)
        assert result[0].status_code == 200


def test_invalid_provider_is_rejected():
    with pytest.raises(ValueError):
        Settings(provider="unknown")


def test_cache_byte_budget_not_just_entry_count():
    p, _ = provider_for(lambda r: httpx.Response(200, content=b"x" * 800000))
    p.template = TEMPLATE
    for i in range(15):
        p.tile_bytes(i, 100, 20)
    assert len(p.cache) == 10
    assert p.cache_bytes == 8000000 <= MAX_CACHE_BYTES
    assert p.cache_bytes == sum(len(entry[1]) for entry in p.cache.values())


def test_geometry_limits_reject_bad_extents_and_point_floods(monkeypatch):
    from services.api.openfreemap import Tile, paint_tile

    image = Image.new("RGB", (390, 390))
    colors = [((c >> 16) & 255, (c >> 8) & 255, c & 255) for c in DAY]
    bad = Tile(0, 0, {"water": {"extent": 0, "features": []}})
    with pytest.raises(ProviderError):
        paint_tile(image, bad, bounds(0, 0, 15), colors, 15)
    monkeypatch.setattr("services.api.openfreemap.MAX_POINTS", 2)
    flood = Tile(
        0,
        0,
        {
            "water": {
                "extent": 4096,
                "features": [
                    {
                        "geometry": {
                            "type": "Polygon",
                            "coordinates": [[[0, 0], [1, 0], [1, 1], [0, 0]]],
                        }
                    }
                ],
            }
        },
    )
    with pytest.raises(ProviderError):
        paint_tile(image, flood, bounds(0, 0, 15), colors, 15)


def test_provider_http_redirect_is_not_followed():
    p, calls = provider_for(
        lambda r: httpx.Response(302, headers={"Location": "http://127.0.0.1/private"})
    )
    with pytest.raises(ProviderError):
        p.render(RenderRequest(**REQUEST))
    assert calls == [TILEJSON]
