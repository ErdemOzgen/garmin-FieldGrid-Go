import io
from concurrent.futures import ThreadPoolExecutor
from urllib.parse import urlsplit

import pytest
from fastapi.testclient import TestClient
from PIL import Image

from services.api.geo import bounds
from services.api.main import Settings, create_app

REQUEST = {"schemaVersion": 1, "requestGeneration": 7, "latDeg": 52.0, "lonDeg": 5.0}


@pytest.fixture
def clock():
    now = [1_789_387_200.0]
    return now


@pytest.fixture
def client(clock):
    with TestClient(create_app(Settings(), lambda: clock[0])) as client:
        yield client


def image_path(metadata):
    url = urlsplit(metadata["imageUrl"])
    return url.path + "?" + url.query


def test_health_labels_synthetic(client):
    assert client.get("/health").json()["provider"] == "synthetic"
    assert client.get("/health").headers["cache-control"] == "no-store"


def test_watch_decimal_strings_preserve_map_center(client):
    response = client.post(
        "/v1/map-renders",
        json=REQUEST | {"latDeg": "52.00002000", "lonDeg": "5.00003000"},
    )
    assert response.status_code == 200
    assert response.json()["bounds3857"] == pytest.approx(
        bounds(52.00002, 5.00003, 15), abs=0.00001, rel=0
    )


@pytest.mark.parametrize("size", [195, 256, 390])
@pytest.mark.parametrize("style", ["day", "night"])
def test_metadata_and_image_are_coherent(client, size, style):
    response = client.post("/v1/map-renders", json=REQUEST | {"imageSize": size, "style": style})
    assert response.status_code == 200
    meta = response.json()
    assert meta["requestGeneration"] == 7
    assert meta["bounds3857"] == pytest.approx(bounds(52, 5, 15))
    assert meta["attribution"] == "SYNTHETIC TEST MAP"
    assert meta["imageWidth"] == meta["imageHeight"] == size
    image = client.get(image_path(meta))
    assert image.status_code == 200
    assert image.headers["x-render-id"] == meta["renderId"]
    assert Image.open(io.BytesIO(image.content)).size == (size, size)
    assert len(image.content) < 30 * 1024
    # Bridge retries are allowed within the short-lived grant.
    assert client.get(image_path(meta)).content == image.content


@pytest.mark.parametrize(
    "change",
    [
        {"schemaVersion": 2},
        {"zoom": 17},
        {"imageSize": 10000},
        {"latDeg": 89},
        {"lonDeg": -181},
        {"style": "https://127.0.0.1/admin"},
        {"url": "https://example.com"},
        {"requestGeneration": -1},
        {"latDeg": None},
        {"latDeg": True},
        {"latDeg": "NaN"},
        {"latDeg": "Infinity"},
        {"latDeg": "52.000000001"},
        {"latDeg": "5.2e1"},
        {"latDeg": "86.00000000"},
    ],
)
def test_invalid_inputs_are_sanitized(client, change):
    response = client.post("/v1/map-renders", json=REQUEST | change)
    assert response.status_code == 422
    assert set(response.json()) == {"code", "retryable", "retryAfterSec", "requestId"}
    assert "latDeg" not in response.text and "example.com" not in response.text


def test_nonfinite_and_malformed_json(client):
    for body in [b'{"latDeg": NaN}', b"broken json"]:
        response = client.post(
            "/v1/map-renders", content=body, headers={"Content-Type": "application/json"}
        )
        assert response.status_code == 422


def test_body_limit_also_applies_without_content_length(client):
    response = client.post("/v1/map-renders", content=iter([b"x" * 1100, b"y" * 1100]))
    assert response.status_code == 413


def test_invalid_image_grants_and_expiry(client, clock):
    first = client.post("/v1/map-renders", json=REQUEST).json()
    second = client.post("/v1/map-renders", json=REQUEST).json()
    url = image_path(first)
    assert client.get(url.replace(first["renderId"], second["renderId"])).status_code == 403
    assert client.get(url[:-1] + ("1" if url[-1] == "0" else "0")).status_code == 403
    clock[0] += 120
    assert client.get(url).status_code == 403
    assert client.get("/v1/images/x?expires=9&sig=x").status_code == 403


def test_cache_is_bounded_and_old_grant_does_not_return_new_image(clock):
    client = TestClient(create_app(Settings(max_entries=1), lambda: clock[0]))
    first = client.post("/v1/map-renders", json=REQUEST).json()
    second = client.post("/v1/map-renders", json=REQUEST | {"zoom": 16}).json()
    assert client.get(image_path(first)).status_code == 410
    assert client.get(image_path(second)).status_code == 200


def test_rate_limit_honors_retry_after_and_recovers(clock):
    client = TestClient(create_app(Settings(requests_per_minute=2), lambda: clock[0]))
    for _ in range(2):
        assert client.post("/v1/map-renders", json=REQUEST).status_code == 200
    blocked = client.post("/v1/map-renders", json=REQUEST)
    assert blocked.status_code == 429 and blocked.headers["Retry-After"] == "60"
    assert blocked.json()["retryable"] is True
    clock[0] += 60
    assert client.post("/v1/map-renders", json=REQUEST).status_code == 200


def test_concurrent_renders_keep_identity():
    client = TestClient(create_app(Settings(max_entries=24, requests_per_minute=100)))

    def request(i):
        return client.post("/v1/map-renders", json=REQUEST | {"requestGeneration": i}).json()

    with ThreadPoolExecutor(max_workers=10) as pool:
        items = list(pool.map(request, range(20)))
    for i, item in enumerate(items):
        if item.get("code") == "RENDER_BUSY":
            assert item["retryable"] is True
            items[i] = request(i)
    assert len({x["renderId"] for x in items}) == 20
    for i, item in enumerate(items):
        assert item["requestGeneration"] == i
        assert client.get(image_path(item)).headers["x-render-id"] == item["renderId"]


def test_private_service_auth_and_no_token_in_url(clock):
    token = "synthetic-test-device-" + "x" * 32
    client = TestClient(
        create_app(Settings(base_url="https://maps.example", device_token=token), lambda: clock[0])
    )
    assert client.post("/v1/map-renders", json=REQUEST).status_code == 401
    response = client.post(
        "/v1/map-renders", json=REQUEST, headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    assert token not in response.text
    assert client.get(image_path(response.json())).status_code == 200


@pytest.mark.parametrize(
    "url",
    [
        "http://maps.example",
        "https://user:pass@maps.example",
        "https://maps.example?a=1",
        "ftp://maps.example",
        "https://maps.example/path",
    ],
)
def test_unsafe_service_origin_is_rejected(url):
    with pytest.raises(ValueError):
        Settings(base_url=url, device_token="x" * 32)


def test_remote_service_requires_token():
    with pytest.raises(ValueError):
        Settings(base_url="https://maps.example")


def test_non_ascii_credentials_fail_closed(clock):
    client = TestClient(create_app(Settings(device_token="x" * 32), lambda: clock[0]))
    response = client.post(
        "/v1/map-renders", json=REQUEST, headers={b"Authorization": b"Bearer \xff"}
    )
    assert response.status_code == 401
    response = client.get(
        "/v1/images/" + "a" * 32, params={"expires": int(clock[0]) + 60, "sig": "ü" * 64}
    )
    assert response.status_code == 403


def test_http_errors_and_invalid_server_limits(client):
    assert client.get("/v1/unknown").json()["code"] == "REQUEST_REJECTED"
    with pytest.raises(ValueError):
        Settings(max_entries=0)


def test_expired_cache_is_removed(clock):
    client = TestClient(create_app(Settings(ttl=2, max_entries=2), lambda: clock[0]))
    first = client.post("/v1/map-renders", json=REQUEST).json()
    clock[0] += 3
    assert client.post("/v1/map-renders", json=REQUEST).status_code == 200
    assert client.get(image_path(first)).status_code == 403
