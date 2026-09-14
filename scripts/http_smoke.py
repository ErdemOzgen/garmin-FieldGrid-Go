"""Exercise a running local service with synthetic coordinates; print no secret URLs."""

import io
import json
import sys
from pathlib import Path

import httpx
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def main():
    config = json.loads((ROOT / ".local/watch.json").read_text())
    if config["baseUrl"] != "http://127.0.0.1:8765":
        raise SystemExit("This smoke test only sends synthetic coordinates to the local service.")
    measurements = []
    with httpx.Client(base_url=config["baseUrl"], timeout=10) as client:
        client.get("/health").raise_for_status()
        for size in (195, 256, 390):
            response = client.post(
                "/v1/map-renders",
                json={
                    "schemaVersion": 1,
                    "requestGeneration": size,
                    "latDeg": 52.0,
                    "lonDeg": 5.0,
                    "imageSize": size,
                },
                headers={"Authorization": f"Bearer {config['devToken']}"},
            )
            response.raise_for_status()
            meta = response.json()
            image = client.get(meta["imageUrl"])
            image.raise_for_status()
            assert Image.open(io.BytesIO(image.content)).size == (size, size)
            assert meta["requestGeneration"] == size
            assert image.headers["X-Render-Id"] == meta["renderId"]
            measurements.append(
                {
                    "size": size,
                    "pngBytes": len(image.content),
                    "httpMs": round(response.elapsed.total_seconds() * 1000, 2),
                }
            )
    report = {
        "status": "PASS",
        "transport": "local HTTP (not Garmin bridge)",
        "synthetic": True,
        "profiles": measurements,
    }
    (ROOT / "build/http-smoke.json").write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    try:
        main()
    except httpx.HTTPError:
        print("Local HTTP smoke FAILED. Check make api; error details redacted.", file=sys.stderr)
        sys.exit(1)
