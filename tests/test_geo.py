import math

import pytest

from services.api.geo import (
    HALF_WORLD,
    MAX_LAT,
    bounds,
    ground_meters_per_pixel,
    pixel,
    project,
    resolution,
    unproject,
)


@pytest.mark.parametrize(
    "lat,lon", [(52, 5), (50.85, 4.35), (0, 0), (-33, 18), (0, 180), (0, -180)]
)
def test_roundtrip_and_center(lat, lon):
    x, y = project(lat, lon)
    back_lat, back_lon = unproject(x, y)
    assert back_lat == pytest.approx(lat)
    assert (back_lon - lon + 180) % 360 - 180 == pytest.approx(0)
    assert pixel(lat, lon, bounds(lat, lon, 15), 390, 390) == pytest.approx((195, 195))


def test_known_control_points_and_pixel_edges():
    assert project(0, 0) == (0, 0)
    assert project(45, 90) == pytest.approx((10018754.171394622, 5621521.486192066))
    box = [-100, -100, 100, 100]
    lat, lon = unproject(-100, 100)
    assert pixel(lat, lon, box, 390, 390) == pytest.approx((0, 0), abs=1e-7)
    lat, lon = unproject(100, -100)
    assert pixel(lat, lon, box, 390, 390) == pytest.approx((390, 390), abs=1e-7)


def test_antimeridian_uses_nearest_world_copy():
    box = bounds(0, 179.999, 14)
    x, y = pixel(0, -179.999, box, 390, 390)
    assert 195 < x < 250
    assert y == pytest.approx(195)


@pytest.mark.parametrize("lat,lon", [(math.nan, 0), (0, math.inf), (-86, 0), (86, 0), (0, 181)])
def test_invalid_coordinates_are_rejected(lat, lon):
    with pytest.raises(ValueError):
        project(lat, lon)


def test_projection_limit_and_ground_scale():
    assert project(MAX_LAT, 180) == pytest.approx((HALF_WORLD, HALF_WORLD))
    assert ground_meters_per_pixel(60, 15) == pytest.approx(resolution(15) / 2)
    assert resolution(14) == 2 * resolution(15)


@pytest.mark.parametrize("size", [195, 256, 390])
def test_resampling_preserves_geographic_frame(size):
    box = bounds(52, 5, 16)
    p = pixel(52.0001, 5.0001, box, size, size)
    full = pixel(52.0001, 5.0001, box, 390, 390)
    assert [v * 390 / size for v in p] == pytest.approx(full)
