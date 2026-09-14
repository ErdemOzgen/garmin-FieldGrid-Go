"""OpenFreeMap -> small raster views; bounded RAM cache, no keys or disk tiles.

Only viewport-intersecting z14 vector tiles are fetched. This renderer deliberately
uses a compact hiking-oriented style, not a full MapLibre style implementation.
"""

import io
import json
import math
import re
import time
from collections import OrderedDict
from dataclasses import dataclass

import httpx
import mapbox_vector_tile
from google.protobuf.message import DecodeError
from PIL import Image, ImageDraw, ImageFont

from services.api.geo import HALF_WORLD, bounds

ATTRIBUTION = "OpenFreeMap | (c) OpenMapTiles | Data from OpenStreetMap"
TILEJSON = "https://tiles.openfreemap.org/planet"
MAX_TILE_BYTES = 1024 * 1024
MAX_CACHE_BYTES = 8 * 1024 * 1024
MAX_CACHE_ENTRIES = 16
MAX_FEATURES = 30000
MAX_POINTS = 300000
# Same colors are supplied to Garmin's image converter (MapJob.palette).
DAY = [
    0xF2F0E7,
    0xDDE7CE,
    0xBBD6A4,
    0x96CADA,
    0xD8D3C9,
    0xB2AAA0,
    0xFFFFFF,
    0xCDAF82,
    0xE5CB8C,
    0xE7A872,
    0x946E45,
    0x6E858A,
    0x203830,
    0x788174,
    0xD6C2D8,
    0xBBBBBB,
]
NIGHT = [
    0x15232A,
    0x243C32,
    0x315344,
    0x264B68,
    0x384248,
    0x4B535A,
    0x77838A,
    0x746249,
    0xA18F62,
    0xAA7960,
    0xC99B64,
    0x779AA3,
    0xEEF4EE,
    0x8A9A8D,
    0x705C78,
    0x555555,
]


class ProviderError(Exception):
    """Sanitized boundary: upstream URLs/coordinates never appear in API errors."""


@dataclass
class Tile:
    x: int  # unwrapped world copy for antimeridian continuity
    y: int
    layers: dict


def tiles_for(box, zoom=14):
    span = 2 * HALF_WORLD / 2**zoom
    west = math.floor((box[0] + HALF_WORLD) / span)
    east = math.floor((box[2] + HALF_WORLD - 1e-7) / span)
    north = max(0, math.floor((HALF_WORLD - box[3]) / span))
    south = min(2**zoom - 1, math.floor((HALF_WORLD - box[1] - 1e-7) / span))
    return [(x, y) for y in range(north, south + 1) for x in range(west, east + 1)]


def screen_point(point, x, y, extent, box, size):
    span = 2 * HALF_WORLD / 2**14
    wx = -HALF_WORLD + (x + point[0] / extent) * span
    wy = HALF_WORLD - (y + point[1] / extent) * span
    return ((wx - box[0]) * size / (box[2] - box[0]), (box[3] - wy) * size / (box[3] - box[1]))


class OpenFreeMap:
    def __init__(self, client=None, clock=time.monotonic):
        self.client = client or httpx.Client(
            timeout=httpx.Timeout(8, connect=3),
            follow_redirects=False,
            headers={
                "User-Agent": "FieldMap/0.1 (personal Connect IQ map viewer)",
                "Accept-Encoding": "identity",
            },
        )
        self.clock = clock
        self.template = None
        self.version = None
        self.template_expires = 0
        self.cache = OrderedDict()
        self.cache_bytes = 0

    def close(self):
        self.client.close()
        self.cache.clear()
        self.cache_bytes = 0

    def fetch(self, url, limit, deadline):
        chunks = bytearray()
        try:
            remaining = deadline - self.clock()
            if remaining <= 0:
                raise ProviderError("upstream deadline")
            with self.client.stream("GET", url, timeout=min(8, remaining)) as response:
                response.raise_for_status()
                for chunk in response.iter_bytes(chunk_size=16384):
                    if self.clock() >= deadline or len(chunks) + len(chunk) > limit:
                        raise ProviderError("upstream resource limit")
                    chunks.extend(chunk)
        except httpx.HTTPError:
            raise ProviderError("upstream unavailable") from None
        if self.clock() >= deadline:
            raise ProviderError("upstream deadline")
        return bytes(chunks)

    def configure(self, deadline):
        if self.template and self.clock() < self.template_expires:
            return
        try:
            data = json.loads(self.fetch(TILEJSON, 32768, deadline))
            template = data["tiles"][0]
            match = re.fullmatch(
                r"https://tiles\.openfreemap\.org/planet/([A-Za-z0-9_-]{1,40})/\{z\}/\{x\}/\{y\}\.pbf",
                template,
            )
            if not match or data["maxzoom"] != 14:
                raise ProviderError("unsupported provider schema")
        except (KeyError, IndexError, TypeError, ValueError):
            raise ProviderError("invalid provider schema") from None
        if template != self.template:
            self.cache.clear()
            self.cache_bytes = 0
        self.template, self.version = template, "openfreemap-" + match[1]
        self.template_expires = self.clock() + 3600

    def tile_bytes(self, x, y, deadline):
        key = (x % 2**14, y)
        hit = self.cache.get(key)
        if hit and hit[0] > self.clock():
            self.cache.move_to_end(key)
            return hit[1]
        if hit:
            self.cache_bytes -= len(self.cache.pop(key)[1])
        data = self.fetch(self.template.format(z=14, x=key[0], y=y), MAX_TILE_BYTES, deadline)
        self.cache[key] = (self.clock() + 24 * 3600, data)
        self.cache_bytes += len(data)
        while len(self.cache) > MAX_CACHE_ENTRIES or self.cache_bytes > MAX_CACHE_BYTES:
            self.cache_bytes -= len(self.cache.popitem(last=False)[1][1])
        return data

    def render(self, request):
        deadline = self.clock() + 18
        self.configure(deadline)
        box = bounds(request.latDeg, request.lonDeg, request.zoom)
        locations = tiles_for(box)
        if not 1 <= len(locations) <= 9:
            raise ProviderError("viewport tile limit")
        n = request.imageSize
        colors = [
            ((c >> 16) & 255, (c >> 8) & 255, c & 255)
            for c in (NIGHT if request.style == "night" else DAY)
        ]
        image = Image.new("RGB", (n, n), colors[0])
        # Hold only one decoded tile at a time; compressed cache is byte-bounded.
        for x, y in locations:
            raw = self.tile_bytes(x, y, deadline)
            try:
                layers = mapbox_vector_tile.decode(raw, default_options={"y_coord_down": True})
                paint_tile(image, Tile(x, y, layers), box, colors, request.zoom)
                del layers
            except (ValueError, KeyError, TypeError, IndexError, OverflowError, DecodeError):
                raise ProviderError("invalid vector tile") from None
            if self.clock() > deadline:
                raise ProviderError("render deadline")
        palette = Image.new("P", (1, 1))
        palette.putpalette([v for c in colors for v in c] + [0] * 720)
        output = io.BytesIO()
        image.quantize(palette=palette, dither=Image.Dither.NONE).save(
            output, format="PNG", optimize=True
        )
        data = output.getvalue()
        if len(data) > 64 * 1024:
            raise ProviderError("raster size limit")
        return data, box, self.version, ATTRIBUTION


def paint_tile(image, tile, box, colors, zoom):
    n = image.width
    draw = ImageDraw.Draw(image)
    points_seen = 0
    features_seen = 0

    def line(points, extent):
        nonlocal points_seen
        points_seen += len(points)
        if points_seen > MAX_POINTS:
            raise ProviderError("geometry limit")
        return [screen_point(p, tile.x, tile.y, extent, box, n) for p in points]

    def features(layer):
        nonlocal features_seen
        data = tile.layers.get(layer, {})
        extent = data.get("extent", 4096)
        if not isinstance(extent, int) or not 1 <= extent <= 65536:
            raise ProviderError("invalid extent")
        for feature in data.get("features", []):
            features_seen += 1
            if features_seen > MAX_FEATURES:
                raise ProviderError("feature limit")
            yield feature, extent

    for layer, color in [
        ("landcover", 1),
        ("landuse", 1),
        ("park", 2),
        ("water", 3),
        ("building", 4),
    ]:
        for feature, extent in features(layer):
            geometry = feature["geometry"]
            polygons = (
                [geometry["coordinates"]]
                if geometry["type"] == "Polygon"
                else geometry["coordinates"]
                if geometry["type"] == "MultiPolygon"
                else []
            )
            for rings in polygons:
                # A per-feature mask preserves holes without erasing underlying layers.
                mask = Image.new("1", image.size)
                painter = ImageDraw.Draw(mask)
                for i, ring in enumerate(rings):
                    coords = line(ring, extent)
                    if len(coords) >= 3:
                        painter.polygon(coords, fill=1 if i == 0 else 0)
                image.paste(colors[color], mask=mask)
    for layer in ["waterway", "transportation"]:
        for feature, extent in features(layer):
            geometry, props = feature["geometry"], feature.get("properties", {})
            lines = (
                [geometry["coordinates"]]
                if geometry["type"] == "LineString"
                else geometry["coordinates"]
                if geometry["type"] == "MultiLineString"
                else []
            )
            kind = props.get("class", "minor")
            path = kind in {"path", "track", "service"}
            major = kind in {"motorway", "trunk", "primary", "secondary"}
            color = 3 if layer == "waterway" else 10 if path else 8 if major else 6
            width = max(1, round(n / 390 * (2 if path else 6 if major else 4)))
            for points in lines:
                coords = line(points, extent)
                if len(coords) < 2:
                    continue
                draw.line(coords, fill=colors[5], width=width + 2)
                draw.line(coords, fill=colors[color], width=width)
    # Compact English/local road and place names, with bounded collision handling.
    font = ImageFont.load_default(size=max(9, round(n / 390 * 14)))
    occupied = []
    for layer in ["transportation_name", "place", "poi", "water_name"]:
        for feature, extent in features(layer):
            props, geometry = feature.get("properties", {}), feature["geometry"]
            name = props.get("name:en") or props.get("name")
            if not isinstance(name, str) or len(occupied) >= 18:
                continue
            name = name[:32]
            coordinates = geometry["coordinates"]
            if geometry["type"] == "Point":
                anchor = screen_point(coordinates, tile.x, tile.y, extent, box, n)
            elif geometry["type"] == "LineString" and coordinates:
                anchor = line(coordinates, extent)[len(coordinates) // 2]
            else:
                continue
            x, y = anchor
            rect = draw.textbbox((x, y), name, font=font, anchor="mm", stroke_width=1)
            if rect[0] < 2 or rect[2] > n - 2 or rect[1] < 2 or rect[3] > n - 2:
                continue
            if any(
                rect[0] < r[2] + 5
                and rect[2] + 5 > r[0]
                and rect[1] < r[3] + 5
                and rect[3] + 5 > r[1]
                for r in occupied
            ):
                continue
            occupied.append(rect)
            draw.text(
                anchor,
                name,
                font=font,
                fill=colors[12],
                anchor="mm",
                stroke_width=1,
                stroke_fill=colors[0],
            )
