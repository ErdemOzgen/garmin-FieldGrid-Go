import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
from services.api.main import Settings, create_app  # noqa: E402
from services.api.models import RenderRequest  # noqa: E402


def main():
    app = create_app(Settings())
    (ROOT / "contracts/openapi.json").write_text(json.dumps(app.openapi(), indent=2) + "\n")
    example = RenderRequest(schemaVersion=1, requestGeneration=42, latDeg=52, lonDeg=5)
    (ROOT / "contracts/render-request.synthetic.json").write_text(
        example.model_dump_json(indent=2) + "\n"
    )


if __name__ == "__main__":
    main()
