"""Small project-specific publishing check; not a replacement for secret scanning services."""

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED = {
    ".git",
    ".venv",
    ".local",
    "build",
    "dist",
    "__pycache__",
    ".pytest_cache",
    ".ruff_cache",
}
PATTERNS = [
    re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(r"(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})"),
]


def source_files():
    listing = subprocess.run(
        ["git", "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    paths = (
        (ROOT / name for name in listing.stdout.split("\0") if name)
        if listing.returncode == 0
        else ROOT.rglob("*")
    )
    for path in sorted(paths):
        relative = path.relative_to(ROOT)
        if not path.is_file() or any(part in EXCLUDED for part in relative.parts):
            continue
        if relative.parts[:3] == ("docs", "evidence", "private"):
            continue
        if path.name.startswith(".env") and path.name != ".env.example":
            continue
        if path.name.startswith(".coverage"):
            continue
        if path.name == ".DS_Store" or path.suffix == ".log":
            continue
        yield path


def main():
    bad = []
    private_values = []
    env = ROOT / ".env"
    if env.exists():
        for line in env.read_text().splitlines():
            if line.startswith("FR165_DEV_TOKEN="):
                private_values.append(line.split("=", 1)[1])
    for path in source_files():
        if path.suffix.lower() in {".der", ".pem", ".key", ".fit", ".prg", ".iq", ".db"}:
            bad.append(str(path.relative_to(ROOT)))
            continue
        try:
            text = path.read_text()
        except UnicodeDecodeError:
            continue
        if any(pattern.search(text) for pattern in PATTERNS) or any(
            value and value in text for value in private_values
        ):
            bad.append(str(path.relative_to(ROOT)))
    tracked = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True)
    if tracked.returncode == 0:
        for name in tracked.stdout.splitlines():
            parts = Path(name).parts
            if any(part in EXCLUDED for part in parts) or name == ".env":
                bad.append(name)
    if bad:
        print("Publishing check FAILED (values redacted):\n" + "\n".join(sorted(set(bad))))
        return 1
    print("Publishing check PASS: no prohibited artifacts or detected credential values.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
