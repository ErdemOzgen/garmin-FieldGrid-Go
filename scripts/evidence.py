"""Report observed local facts; never turns missing physical evidence into a pass."""

import hashlib
import json
import re
import subprocess
import xml.etree.ElementTree as ET
from datetime import UTC, datetime
from pathlib import Path

from watch import doctor, watch_source_hash

ROOT = Path(__file__).resolve().parents[1]


def source_digest():
    digest = hashlib.sha256()
    paths = [
        p
        for base in ["apps/watch", "services", "scripts", "tests", "contracts"]
        for p in (ROOT / base).rglob("*")
        if p.is_file() and "__pycache__" not in p.parts and p.suffix != ".pyc"
    ]
    for path in sorted(paths):
        digest.update(str(path.relative_to(ROOT)).encode() + b"\0" + path.read_bytes())
    return digest.hexdigest()


def main():
    output = ROOT / "docs/evidence"
    output.mkdir(parents=True, exist_ok=True)
    report = {
        "measuredAtUtc": datetime.now(UTC).isoformat(),
        "environment": doctor(),
        "sourceSha256": source_digest(),
        "physicalTests": "NOT RUN",
        "visualReview": "NOT RUN",
    }
    visual = output / "simulator.json"
    if visual.exists():
        observed = json.loads(visual.read_text())
        report["visualReview"] = {
            "status": observed["status"]
            if observed.get("watchSourceSha256") == watch_source_hash()
            else "STALE",
            "record": "docs/evidence/simulator.json",
            "physicalAcceptance": "NOT RUN",
        }
    for name in ["FieldMap.prg", "FieldMap-tests.prg"]:
        path = ROOT / "build" / name
        manifest = path.with_suffix(path.suffix + ".json")
        record = json.loads(manifest.read_text()) if manifest.exists() else {}
        current = (
            path.exists()
            and record.get("sourceSha256") == watch_source_hash()
            and record.get("artifactSha256") == hashlib.sha256(path.read_bytes()).hexdigest()
        )
        report[name] = {
            "status": "PASS" if current else "NOT RUN" if not path.exists() else "STALE",
            "bytes": path.stat().st_size if path.exists() else None,
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None,
        }
    junit = ROOT / "build/pytest.xml"
    if junit.exists():
        suite = ET.parse(junit).getroot().find("testsuite")
        report["pythonTests"] = {
            k: int(suite.attrib.get(k, 0)) for k in ["tests", "errors", "failures", "skipped"]
        }
    else:
        report["pythonTests"] = "NOT RUN"
    log = ROOT / "build/watch-tests.log"
    text = log.read_text() if log.exists() else ""
    summary = re.search(r"^PASSED \(passed=(\d+), failed=0, errors=0\)$", text, re.MULTILINE)
    result_file = ROOT / "build/watch-test-result.json"
    tested = json.loads(result_file.read_text()) if result_file.exists() else {}
    fresh = (
        tested.get("sourceSha256") == watch_source_hash()
        and report["FieldMap-tests.prg"]["status"] == "PASS"
        and tested.get("artifactSha256") == report["FieldMap-tests.prg"]["sha256"]
    )
    report["watchTests"] = {
        "status": "PASS"
        if summary and fresh
        else "NOT RUN"
        if not text
        else "STALE"
        if summary
        else "FAIL",
        "passed": int(summary[1]) if summary else 0,
    }
    if log.exists():
        (output / "watch-tests.txt").write_text(text)
    for name in ["http-smoke.json", "audit.json"]:
        path = ROOT / "build" / name
        if path.exists():
            report[name] = json.loads(path.read_text())
    result = subprocess.run(["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True)
    report["gitCommitAtMeasurement"] = result.stdout.strip() if result.returncode == 0 else None
    (output / "automated.json").write_text(json.dumps(report, indent=2) + "\n")
    print("Evidence written to docs/evidence/automated.json. Physical acceptance remains NOT RUN.")


if __name__ == "__main__":
    main()
