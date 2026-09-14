"""Generate clearly artificial POC inputs; no location API or external requests."""

import json
import sys
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from services.api.models import RenderRequest  # noqa: E402
from services.api.renderer import render  # noqa: E402


def main():
    dest = ROOT / "tests/fixtures"
    for size in (195, 256, 390):
        for style in ("day", "night"):
            request = RenderRequest(
                schemaVersion=1,
                requestGeneration=1,
                latDeg=52.0,
                lonDeg=5.0,
                imageSize=size,
                style=style,
            )
            data, box = render(request)
            (dest / f"synthetic-{size}-{style}.png").write_bytes(data)
            (dest / f"synthetic-{size}-{style}.json").write_text(
                json.dumps(
                    {"synthetic": True, "request": request.model_dump(), "bounds3857": box},
                    indent=2,
                )
                + "\n"
            )
    # Original code-generated app icon (no Garmin trademark).
    icon = Image.new("RGBA", (54, 54), (0, 0, 0, 0))
    draw = ImageDraw.Draw(icon)
    draw.ellipse((1, 1, 52, 52), fill="#187c69")
    draw.line([(12, 36), (22, 19), (32, 34), (43, 15)], fill="#ebf2e9", width=5)
    draw.ellipse((19, 16, 27, 24), fill="#f0be56")
    icon.save(ROOT / "apps/watch/resources/drawables/icon.png")
    points = [
        f'<trkpt lat="{52 + i * 0.00002:.6f}" lon="{5 + i * 0.00003:.6f}">'
        f"<time>2026-09-14T12:{i // 60:02d}:{i % 60:02d}Z</time></trkpt>"
        for i in range(180)
    ]
    (dest / "synthetic-walk.gpx").write_text(
        '<?xml version="1.0"?><gpx version="1.1" creator="FieldMap synthetic test" '
        'xmlns="http://www.topografix.com/GPX/1/1"><trk><name>SYNTHETIC ONLY</name><trkseg>'
        + "\n".join(points)
        + "</trkseg></trk></gpx>\n"
    )


if __name__ == "__main__":
    main()
