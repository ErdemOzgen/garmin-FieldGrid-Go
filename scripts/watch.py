"""Reproducible local tool entry points; never installs into system runtimes."""

import argparse
import hashlib
import json
import os
import platform
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[1]
LOCAL = ROOT / ".local"
BUILD = ROOT / "build"
GARMIN = Path.home() / "Library/Application Support/Garmin/ConnectIQ"
TARGET = "fr165"


def watch_source_hash():
    digest = hashlib.sha256()
    for path in sorted((ROOT / "apps/watch").rglob("*")):
        if path.is_file():
            digest.update(str(path.relative_to(ROOT)).encode() + b"\0" + path.read_bytes())
    return digest.hexdigest()


def sdk_path():
    configured = os.getenv("CIQ_SDK_HOME")
    config_file = LOCAL / "toolchain.json"
    if not configured and config_file.exists():
        configured = json.loads(config_file.read_text()).get("sdk")
    candidates = [Path(configured)] if configured else []
    current = GARMIN / "current-sdk.cfg"
    if current.exists():
        candidates.append(Path(current.read_text().strip()))
    candidates.extend(sorted((GARMIN / "Sdks").glob("*"), reverse=True))
    for candidate in candidates:
        if (candidate / "bin/monkeybrains.jar").exists():
            return candidate
    return None


def java_path():
    configured = os.getenv("CIQ_JAVA_HOME")
    if configured:
        return str(Path(configured) / "bin/java")
    if sys.platform == "darwin":
        p = subprocess.run(["/usr/libexec/java_home", "-v", "11"], capture_output=True, text=True)
        if p.returncode == 0:
            return str(Path(p.stdout.strip()) / "bin/java")
    return shutil.which("java")


def doctor():
    sdk = sdk_path()
    java = java_path()
    device = GARMIN / "Devices" / TARGET / "compiler.json"
    data = json.loads(device.read_text()) if device.exists() else {}
    report = {
        "os": platform.system(),
        "osVersion": platform.mac_ver()[0] or platform.release(),
        "architecture": platform.machine(),
        "python": platform.python_version(),
        "venvPresent": (ROOT / ".venv/bin/python").exists(),
        "sdk": (sdk / "bin/version.txt").read_text().strip() if sdk else "NOT FOUND",
        "java": "NOT FOUND",
        "deviceId": data.get("deviceId", "NOT FOUND"),
        "deviceName": data.get("displayName"),
        "deviceVersion": data.get("deviceVersion"),
        "resolution": data.get("resolution"),
        "apiGroup": data.get("deviceGroup"),
        "reportedWatchMemoryBytes": next(
            (x["memoryLimit"] for x in data.get("appTypes", []) if x["type"] == "watchApp"), None
        ),
        "physicalFirmware": "NOT MEASURED",
        "physicalIOS": "NOT MEASURED",
        "physicalGCM": "NOT MEASURED",
    }
    if java:
        p = subprocess.run([java, "-version"], capture_output=True, text=True)
        report["java"] = (p.stderr or p.stdout).splitlines()[0] if p.returncode == 0 else "FAILED"
    print(json.dumps(report, indent=2))
    return report


def configure_resources(simulator=False, offline=False):
    directory = LOCAL / "watch-resources"
    directory.mkdir(parents=True, exist_ok=True)
    configuration = LOCAL / "watch.json"
    data = json.loads(configuration.read_text()) if configuration.exists() else {}
    base_url = data.get("baseUrl", "").rstrip("/")
    token = data.get("devToken", "")
    allow_local = data.get("allowLocalHttp", False)
    if offline or (allow_local and not simulator):
        # A simulator loopback origin must never leak into the physical-watch build.
        base_url, token, allow_local = "", "", False
    from urllib.parse import urlsplit

    parts = urlsplit(base_url)
    if base_url and (
        (parts.scheme != "https" and not (allow_local and base_url == "http://127.0.0.1:8765"))
        or not parts.hostname
        or parts.username
        or parts.password
        or parts.query
        or parts.fragment
        or parts.path not in {"", "/"}
    ):
        raise SystemExit("Invalid watch origin. Use HTTPS, or explicit local simulator HTTP.")
    resources = (
        "<strings>\n"
        f'<string id="ConfigBaseUrl">{escape(base_url or "DISABLED")}</string>\n'
        f'<string id="ConfigDevToken">{escape(token or "DISABLED")}</string>\n'
        f'<string id="ConfigAllowLocalHttp">{str(bool(allow_local)).lower()}</string>\n'
        "</strings>\n"
    )
    # Compile-time resources cannot be shadowed by old simulator Properties.
    (directory / "properties.xml").unlink(missing_ok=True)
    path = directory / "configuration.xml"
    path.write_text(resources)
    path.chmod(0o600)


def build(unit_tests=False, simulator=False, offline=False):
    sdk = sdk_path()
    java = java_path()
    if sdk is None or java is None:
        raise SystemExit("Missing Garmin SDK / Java. Run make doctor; see docs/setup.md.")
    if not (GARMIN / "Devices/fr165/compiler.json").exists():
        raise SystemExit("Install only Forerunner 165 in Garmin SDK Manager > Devices > API 5.2.")
    lock = json.loads((ROOT / "toolchain.lock.json").read_text())
    actual = (sdk / "bin/version.txt").read_text().strip()
    device = json.loads((GARMIN / "Devices/fr165/compiler.json").read_text())
    if actual != lock["sdkVersion"] or device["deviceVersion"] != lock["deviceVersion"]:
        raise SystemExit(
            "SDK/device version differs from toolchain.lock.json. Review the update first."
        )
    configure_resources(simulator=simulator, offline=offline)
    BUILD.mkdir(exist_ok=True)
    key = Path(os.getenv("CIQ_DEVELOPER_KEY", str(LOCAL / "keys/developer.der")))
    if not key.exists():
        key.parent.mkdir(parents=True, exist_ok=True)
        pem = subprocess.run(
            ["openssl", "genpkey", "-algorithm", "RSA", "-pkeyopt", "rsa_keygen_bits:4096"],
            check=True,
            capture_output=True,
        ).stdout
        der = subprocess.run(
            ["openssl", "pkcs8", "-topk8", "-inform", "PEM", "-outform", "DER", "-nocrypt"],
            input=pem,
            check=True,
            capture_output=True,
        ).stdout
        with os.fdopen(os.open(key, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), "wb") as stream:
            stream.write(der)
    name = "FieldMap-simulator.prg" if simulator else "FieldMap.prg"
    if offline:
        name = "FieldMap-offline-simulator.prg"
    output = BUILD / ("FieldMap-tests.prg" if unit_tests else name)
    cmd = [
        java,
        "-Xmx1g",
        "-jar",
        str(sdk / "bin/monkeybrains.jar"),
        "-f",
        "monkey.jungle",
        "-d",
        TARGET,
        "-y",
        str(key),
        "-o",
        str(output),
        "-w",
        "-l",
        "1",
    ]
    if unit_tests:
        cmd.append("-t")
    proc = subprocess.run(cmd, cwd=ROOT / "apps/watch", capture_output=True, text=True)
    log = proc.stdout + proc.stderr
    # Tool paths are useful locally, but do not publish absolute user paths.
    safe_log = log.replace(str(ROOT), "$PROJECT").replace(str(Path.home()), "$USER")
    (BUILD / ("watch-test-build.log" if unit_tests else "watch-build.log")).write_text(safe_log)
    print(safe_log, end="")
    if proc.returncode:
        raise SystemExit(proc.returncode)
    if "BUILD SUCCESSFUL" not in log:
        raise SystemExit("Compiler did not return a successful build summary.")
    revision = subprocess.run(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, capture_output=True, text=True
    )
    changes = subprocess.run(
        ["git", "status", "--porcelain", "apps/watch"], cwd=ROOT, capture_output=True, text=True
    )
    record = {
        "status": "PASS",
        "target": TARGET,
        "sdkVersion": actual,
        "deviceVersion": device["deviceVersion"],
        "sourceSha256": watch_source_hash(),
        "sourceCommit": revision.stdout.strip() if revision.returncode == 0 else None,
        "watchSourcesDirty": bool(changes.stdout.strip()) if changes.returncode == 0 else None,
        "artifactSha256": hashlib.sha256(output.read_bytes()).hexdigest(),
        "unitTests": unit_tests,
        "simulator": simulator,
        "offline": offline,
        "warnings": log.count("WARNING:"),
    }
    output.with_suffix(output.suffix + ".json").write_text(json.dumps(record, indent=2) + "\n")
    print(f"Built {output.name}, SHA256 {hashlib.sha256(output.read_bytes()).hexdigest()}")
    return output


def simulate(unit_tests=False, offline=False):
    output = build(unit_tests, simulator=True, offline=offline)
    sdk = sdk_path()
    java = java_path()
    subprocess.run(["open", "-a", str(sdk / "bin/ConnectIQ.app")], check=True)
    cmd = [
        java,
        "-classpath",
        str(sdk / "bin/monkeybrains.jar"),
        "com.garmin.monkeybrains.monkeydodeux.MonkeyDoDeux",
        "-f",
        str(output),
        "-d",
        TARGET,
        "-s",
        str(sdk / "bin/shell"),
    ]
    if unit_tests:
        cmd.append("-t")
    if not unit_tests:
        print("Simulator running; exit the watch app to finish this command.", flush=True)
        with (BUILD / "simulator.log").open("w") as log_file:
            for attempt in range(3):
                connect_failed = False
                with subprocess.Popen(
                    cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True
                ) as process:
                    for line in process.stdout:
                        safe_line = line.replace(str(ROOT), "$PROJECT").replace(
                            str(Path.home()), "$USER"
                        )
                        connect_failed |= line.strip() == "Unable to connect to simulator."
                        log_file.write(safe_line)
                        log_file.flush()
                        print(safe_line, end="", flush=True)
                    return_code = process.wait()
                if not connect_failed or attempt == 2:
                    break
                time.sleep(1)
        if return_code:
            raise SystemExit(return_code)
        return
    # A failed/timed-out rerun must never leave the previous PASS as fresh evidence.
    (BUILD / "watch-test-result.json").unlink(missing_ok=True)
    (BUILD / "watch-tests.log").write_text("")
    print("Running compiled simulator tests (90 second timeout).", flush=True)
    for attempt in range(3):
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=90)
        except subprocess.TimeoutExpired:
            (BUILD / "watch-tests.log").write_text(
                "FAILED: simulator timed out after 90 seconds.\n"
            )
            raise SystemExit(
                "Simulator timed out; restart the simulator and rerun tests."
            ) from None
        if "Unable to connect to simulator." not in result.stdout + result.stderr or attempt == 2:
            break
        time.sleep(1)
    log = (
        (result.stdout + result.stderr)
        .replace(str(ROOT), "$PROJECT")
        .replace(str(Path.home()), "$USER")
    )
    (BUILD / ("watch-tests.log" if unit_tests else "simulator.log")).write_text(log)
    print(log)
    if unit_tests:
        # SDK 9.2.0 MonkeyDoDeux returns 1 even for its explicit PASSED result.
        # Fail closed unless a complete, non-empty success summary is present.
        summary = re.search(r"^PASSED \(passed=(\d+), failed=0, errors=0\)$", log, re.MULTILINE)
        if not summary or int(summary[1]) < 1 or "\nFAILED" in log:
            raise SystemExit(result.returncode or 1)
        (BUILD / "watch-test-result.json").write_text(
            json.dumps(
                {
                    "status": "PASS",
                    "passed": int(summary[1]),
                    "rawSdkExitCode": result.returncode,
                    "sourceSha256": watch_source_hash(),
                    "artifactSha256": hashlib.sha256(output.read_bytes()).hexdigest(),
                },
                indent=2,
            )
            + "\n"
        )
        return
    if result.returncode:
        raise SystemExit(result.returncode)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["doctor", "build", "test", "sim", "sim-offline"])
    args = parser.parse_args()
    {
        "doctor": doctor,
        "build": build,
        "test": lambda: simulate(True),
        "sim": simulate,
        "sim-offline": lambda: simulate(offline=True),
    }[args.command]()
