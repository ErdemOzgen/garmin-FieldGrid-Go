"""Run one bounded G0 process, without URL/query access logs."""

import os
import sys
from pathlib import Path

import uvicorn

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))


def main():
    env_file = ROOT / ".env"
    if env_file.exists():
        for line in env_file.read_text().splitlines():
            key, separator, value = line.partition("=")
            if separator and key in {"FR165_PUBLIC_BASE_URL", "FR165_DEV_TOKEN"}:
                os.environ.setdefault(key, value)
    uvicorn.run(
        "services.api.main:app",
        host="127.0.0.1",
        port=8765,
        access_log=False,
        proxy_headers=False,
        workers=1,
        limit_concurrency=32,
        timeout_keep_alive=5,
    )


if __name__ == "__main__":
    main()
