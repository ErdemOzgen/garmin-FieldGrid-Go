"""Pixel-edge Web Mercator contract; synthetic inputs only in automated evidence."""

import math

RADIUS = 6_378_137.0
HALF_WORLD = math.pi * RADIUS
MAX_LAT = 85.0511287798066


def project(lat: float, lon: float) -> tuple[float, float]:
    if not (math.isfinite(lat) and math.isfinite(lon)):
        raise ValueError("non-finite coordinate")
    if abs(lat) > MAX_LAT or abs(lon) > 180:
        raise ValueError("outside supported projection")
    return RADIUS * math.radians(lon), RADIUS * math.asinh(math.tan(math.radians(lat)))


def unproject(x: float, y: float) -> tuple[float, float]:
    return math.degrees(math.atan(math.sinh(y / RADIUS))), (
        math.degrees(x / RADIUS) + 180
    ) % 360 - 180


def resolution(zoom: int) -> float:
    return 2 * HALF_WORLD / (256 * 2**zoom)


def bounds(lat: float, lon: float, zoom: int, width: int = 390) -> list[float]:
    x, y = project(lat, lon)
    half = width * resolution(zoom) / 2
    return [x - half, y - half, x + half, y + half]


def pixel(lat: float, lon: float, box: list[float], width: int, height: int) -> tuple[float, float]:
    x, y = project(lat, lon)
    center = (box[0] + box[2]) / 2
    # Nearest world copy preserves continuity across +/-180 degrees.
    x += round((center - x) / (2 * HALF_WORLD)) * (2 * HALF_WORLD)
    return (x - box[0]) / (box[2] - box[0]) * width, (box[3] - y) / (box[3] - box[1]) * height


def ground_meters_per_pixel(lat: float, zoom: int) -> float:
    return resolution(zoom) * math.cos(math.radians(lat))
