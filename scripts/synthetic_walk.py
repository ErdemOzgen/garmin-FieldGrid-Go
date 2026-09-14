"""Create a reproducible 20-minute circular GPS fixture, never real location data."""

import math
from datetime import UTC, datetime, timedelta
from pathlib import Path


def main():
    destination = Path(__file__).resolve().parents[1] / "build/synthetic-20min.gpx"
    destination.parent.mkdir(exist_ok=True)
    start = datetime(2026, 9, 14, 12, tzinfo=UTC)
    points = []
    for i in range(1200):
        angle = i * 2 * math.pi / 240
        lat = 52 + 0.001 * math.sin(angle)
        lon = 5 + 0.001 * math.cos(angle)
        timestamp = (start + timedelta(seconds=i)).isoformat().replace("+00:00", "Z")
        points.append(f'<trkpt lat="{lat:.8f}" lon="{lon:.8f}"><time>{timestamp}</time></trkpt>')
    destination.write_text(
        '<?xml version="1.0"?><gpx version="1.1" creator="FieldMap synthetic test" '
        'xmlns="http://www.topografix.com/GPX/1/1"><trk>'
        "<name>SYNTHETIC ONLY - circular stress fixture</name><trkseg>"
        + "".join(points)
        + "</trkseg></trk></gpx>"
    )
    print("Created build/synthetic-20min.gpx (SYNTHETIC ONLY).")


if __name__ == "__main__":
    main()
