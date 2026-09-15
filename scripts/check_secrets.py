"""Redacted publication checks for the working tree, Git index and reachable history.

This is a project guard, not a guarantee that arbitrary secrets can be recognized.
No source text or matched credential is printed.
"""

import argparse
import json
import math
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED = {
    ".git",
    ".venv",
    "venv",
    "env",
    ".local",
    "build",
    "dist",
    "__pycache__",
    ".pytest_cache",
    ".ruff_cache",
    "htmlcov",
    "node_modules",
    ".idea",
    ".aws",
    ".ssh",
    ".gnupg",
    ".terraform",
    "sdk",
    "sdks",
}
PRIVATE_SUFFIXES = {
    ".der",
    ".pem",
    ".key",
    ".p12",
    ".pfx",
    ".jks",
    ".keystore",
    ".fit",
    ".tcx",
    ".gpx",
    ".prg",
    ".iq",
    ".db",
    ".sqlite",
    ".sqlite3",
    ".log",
    ".heic",
    ".heif",
    ".zip",
    ".dmg",
    ".pkg",
    ".mobileprovision",
    ".tfstate",
    ".bak",
    ".swp",
}
SYNTHETIC_GPX = "tests/fixtures/synthetic-walk.gpx"
SECRET_NAME = re.compile(r"(?i)(secret|token|password|passwd|api[_-]?key|private[_-]?key)")
ASSIGNMENT = re.compile(
    r"""(?im)["']?([\w.-]*(?:secret|token|password|passwd|api[_-]?key|private[_-]?key)"""
    r"""[\w.-]*)["']?\s*[:=]\s*["']?([^\s"',;#}]+)"""
)
PATTERNS = {
    "private key": re.compile(rb"-----BEGIN (?:[A-Z0-9]+ )*PRIVATE KEY-----"),
    "GitHub token": re.compile(rb"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})\b"),
    "AWS access key": re.compile(rb"\b(?:AKIA|ASIA)[A-Z0-9]{16}\b"),
    "Google API key": re.compile(rb"\bAIza[0-9A-Za-z_-]{35}\b"),
    "Slack token": re.compile(rb"\bxox[baprs]-[0-9A-Za-z-]{20,}\b"),
    "Stripe live key": re.compile(rb"\b[rs]k_live_[0-9A-Za-z]{20,}\b"),
    "OpenAI key": re.compile(rb"\bsk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{40,}\b"),
    "Hugging Face token": re.compile(rb"\bhf_[A-Za-z0-9]{30,}\b"),
    "JWT": re.compile(rb"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"),
    "credential in URL": re.compile(rb"[a-z][a-z0-9+.-]*://[^\s/:]+:[^\s/@]+@[^\s/\"'<>]+", re.I),
}


def git(root, *args):
    return subprocess.run(["git", *args], cwd=root, capture_output=True, check=True).stdout


def prohibited(name):
    path = Path(name)
    lower = path.name.lower()
    parts = {p.lower() for p in path.parts}
    return (
        bool(parts & EXCLUDED)
        or path.parts[:3] == ("docs", "evidence", "private")
        or (lower.startswith(".env") and lower != ".env.example")
        or lower.startswith(".coverage")
        or lower
        in {
            ".ds_store",
            ".npmrc",
            ".pypirc",
            "credentials",
            "credentials.json",
            "secrets.json",
            "secrets.yaml",
            "secrets.yml",
            "id_rsa",
            "id_ed25519",
        }
        or (lower == "settings.json" and ".vscode" in parts)
        or lower.startswith(("service-account", "service_account"))
        or (path.suffix.lower() in PRIVATE_SUFFIXES and name != SYNTHETIC_GPX)
        or lower.endswith((".sqlite-wal", ".sqlite-shm", ".db-wal", ".db-shm", ".tfstate.backup"))
        or path.parts[:3] in {("apps", "watch", "bin"), ("apps", "watch", "gen")}
    )


def source_files(root=ROOT):
    """Tracked files plus untracked, nonignored files; also works from source ZIP."""
    try:
        names = git(root, "ls-files", "-z", "--cached", "--others", "--exclude-standard")
        paths = {root / n.decode() for n in names.split(b"\0") if n}
    except subprocess.CalledProcessError:
        paths = {p for p in root.rglob("*") if not prohibited(str(p.relative_to(root)))}
    for path in sorted(paths):
        if path.is_symlink() or path.is_file():
            yield path


def placeholder(value):
    return value in {"", "null", "None", "false", "true", "REDACTED", "<redacted>"} or (
        value.startswith(("${", "$", "<", "/path/", "/private/path/"))
        or value == "generate-a-random-token-with-make-dev-config"
    )


def private_values(root):
    """Read only local configuration, never log values or private key contents."""
    values = set()
    paths = [p for p in root.glob(".env*") if p.name != ".env.example"]
    paths += list((root / ".local").glob("*.json"))

    def collect(obj):
        if isinstance(obj, dict):
            for key, val in obj.items():
                if SECRET_NAME.search(key) and isinstance(val, str) and len(val) >= 8:
                    if not placeholder(val):
                        values.add(val.encode())
                collect(val)
        elif isinstance(obj, list):
            for val in obj:
                collect(val)

    for path in paths:
        if not path.is_file() or path.is_symlink():
            continue
        text = path.read_text()
        if path.suffix == ".json":
            collect(json.loads(text))
        else:
            for match in ASSIGNMENT.finditer(text):
                val = match[2]
                if len(val) >= 8 and not placeholder(val):
                    values.add(val.encode())
    return values


def findings(data, known=()):
    result = set()
    for label, pattern in PATTERNS.items():
        for match in pattern.finditer(data):
            # Exact reserved-domain negative test fixture, never a host-wide exemption.
            if label == "credential in URL" and match[0] == b"https://user:pass@maps.example":
                continue
            result.add(label)
    if any(value in data for value in known):
        result.add("local credential value")
    for match in ASSIGNMENT.finditer(data.decode("utf-8", errors="replace")):
        value = match[2]
        if len(value) < 20 or placeholder(value):
            continue
        entropy = -sum(
            (n / len(value)) * math.log2(n / len(value)) for n in Counter(value).values()
        )
        if entropy >= 3.5 and re.fullmatch(r"[A-Za-z0-9_+/=.-]+", value):
            result.add("possible secret assignment")
    return result


def snapshots(root, mode):
    if mode == "working":
        for path in source_files(root):
            name = str(path.relative_to(root))
            yield name, b"" if path.is_symlink() else path.read_bytes(), path.is_symlink()
        return
    refs = [None] if mode == "staged" else git(root, "rev-list", "--all").splitlines()
    seen = set()
    for ref in refs:
        records = (
            git(root, "ls-files", "--stage", "-z")
            if ref is None
            else git(root, "ls-tree", "-r", "-z", ref.decode())
        )
        for entry in records.split(b"\0"):
            if not entry:
                continue
            meta, name = entry.split(b"\t", 1)
            fields = meta.split()
            oid = fields[1] if ref is None else fields[2]
            if (name, oid) in seen:
                continue
            seen.add((name, oid))
            # Symlinks and submodules can hide content from the publication audit.
            unsafe = fields[0] in {b"120000", b"160000"}
            yield (
                name.decode(),
                b"" if unsafe else git(root, "cat-file", "blob", oid.decode()),
                unsafe,
            )


def check(root=ROOT, mode="working"):
    known = private_values(root)
    bad = []
    count = 0
    for name, data, unsafe in snapshots(root, mode):
        count += 1
        reasons = {"prohibited artifact"} if prohibited(name) else set()
        if unsafe:
            reasons.add("symlink or submodule cannot be audited")
        reasons |= findings(data, known)
        if reasons:
            bad.append((name, ", ".join(sorted(reasons))))
    return sorted(set(bad)), count


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--staged", action="store_true", help="Scan the actual Git index")
    group.add_argument("--history", action="store_true", help="Scan all reachable commits and tags")
    args = parser.parse_args(argv)
    mode = "staged" if args.staged else "history" if args.history else "working"
    try:
        bad, count = check(mode=mode)
    except (OSError, ValueError, subprocess.CalledProcessError):
        print("Publishing check FAILED: scan could not complete; details redacted.")
        return 1
    if bad:
        print(f"Publishing check FAILED ({mode}; values redacted):")
        for name, reason in bad:
            print(f"{name}: {reason}")
        return 1
    print(
        f"Publishing check PASS ({mode}, {count} entries): no detected secrets or prohibited files."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
