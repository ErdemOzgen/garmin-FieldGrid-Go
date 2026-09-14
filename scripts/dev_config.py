"""Generate one local G0 credential without printing it or overwriting configuration."""

import argparse
import json
import os
import secrets
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]


def write_private(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    with os.fdopen(os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "w") as stream:
        stream.write(text)


def main():
    parser = argparse.ArgumentParser()
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--simulator", action="store_true")
    source.add_argument("--url", help="Private HTTPS origin for a G0 device experiment")
    args = parser.parse_args()
    url = "http://127.0.0.1:8765" if args.simulator else args.url.rstrip("/")
    parsed = urlsplit(url)
    if not args.simulator and (
        parsed.scheme != "https"
        or not parsed.hostname
        or parsed.path
        or parsed.username
        or parsed.password
        or parsed.query
        or parsed.fragment
    ):
        raise SystemExit("Provide a valid HTTPS origin without path, credentials or query.")
    for path in [ROOT / ".env", ROOT / ".local/watch.json"]:
        if path.exists():
            raise SystemExit(
                f"{path.name} exists; edit local configuration explicitly. Not overwritten."
            )
    token = secrets.token_urlsafe(32)
    write_private(
        ROOT / ".local/watch.json",
        json.dumps(
            {
                "baseUrl": url,
                "devToken": token,
                "allowLocalHttp": args.simulator,
            },
            indent=2,
        )
        + "\n",
    )
    write_private(
        ROOT / ".env",
        f"FR165_PUBLIC_BASE_URL={url}\nFR165_DEV_TOKEN={token}\nFR165_MAP_PROVIDER=openfreemap\n",
    )
    print("Private .env and .local/watch.json created. Credential values are not displayed.")
    print("Run make api, then make sim. Rebuild before copying the PRG to a physical watch.")


if __name__ == "__main__":
    main()
