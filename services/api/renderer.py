"""Deterministic test grid, deliberately not a real map provider.

The coordinate-aligned grid has no invented street names. All three pixel profiles
cover the same 390-display-pixel geographic viewport.
"""

import io
import math

from PIL import Image, ImageDraw

from services.api.geo import bounds
from services.api.models import RenderRequest


def render(request: RenderRequest) -> tuple[bytes, list[float]]:
    box = bounds(request.latDeg, request.lonDeg, request.zoom)
    n = request.imageSize
    night = request.style == "night"
    background, grid, major = (
        ("#15232a", "#2c434a", "#7c969c") if night else ("#eaf0e9", "#c5d5ca", "#718d80")
    )
    image = Image.new("RGB", (n, n), background)
    draw = ImageDraw.Draw(image)
    scale = n / (box[2] - box[0])
    spacing = 100 if request.zoom >= 15 else 200
    for x in range(math.ceil(box[0] / spacing), math.floor(box[2] / spacing) + 1):
        px = round((x * spacing - box[0]) * scale)
        draw.line(
            [(px, 0), (px, n)], fill=major if x % 5 == 0 else grid, width=2 if x % 5 == 0 else 1
        )
    for y in range(math.ceil(box[1] / spacing), math.floor(box[3] / spacing) + 1):
        py = round((box[3] - y * spacing) * scale)
        draw.line(
            [(0, py), (n, py)], fill=major if y % 5 == 0 else grid, width=2 if y % 5 == 0 else 1
        )
    # Corner fiducials reveal cropping, resampling and orientation errors.
    for (x, y), color in zip(
        [(0, 0), (n - 12, 0), (0, n - 12), (n - 12, n - 12)],
        ["#ff705b", "#479bea", "#ecc75c", "#5dbb89"],
        strict=True,
    ):
        draw.rectangle((x, y, x + 11, y + 11), fill=color)
    draw.text((n // 2, n // 2 - 25), "SYNTHETIC", anchor="mm", fill=major)
    draw.text((n // 2, n // 2 + 25), f"{n}px / z{request.zoom}", anchor="mm", fill=major)
    output = io.BytesIO()
    image.quantize(colors=16).save(output, format="PNG", optimize=True)
    return output.getvalue(), box
