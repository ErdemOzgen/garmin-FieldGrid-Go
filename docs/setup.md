# Isolated development setup

## Python

Use an existing Python 3.12 through 3.14 installation. `make setup` creates `.venv`
and installs the exact versions in `requirements-dev.lock`. It does not modify
system Python, Homebrew, shell startup files or global Node packages. An unsupported
Python version is rejected before installation. For example, on Apple Silicon:

```sh
make setup PYTHON=/opt/homebrew/bin/python3
```

This selects an existing interpreter; it does not install Python. If `.venv` was
created with an unsupported interpreter, move it outside the source tree and
recreate it. Runtime dependencies are in `requirements.lock`; direct dependencies
are declared in `pyproject.toml`. Recheck tests and security when updating locks.

## Garmin SDK

Obtain SDK 9.2.0 and the Forerunner 165 device package using the official
[SDK Manager](https://developer.garmin.com/connect-iq/sdk/). Complete any Garmin
sign in yourself. Only the required device/font packages are needed. Keep all SDK
files outside Git. The verified device ID is `fr165`, with a 390 × 390 display.

The local validation used `/tmp/fr165-tools/sdk`. Temporary directories can be
removed by macOS; use your own persistent SDK location if preferred:

```sh
export CIQ_SDK_HOME="/path/to/connectiq-sdk"
make doctor
```

This changes only the current shell environment. Alternatively set `sdk` in the
ignored `.local/toolchain.json`. The scripts also discover SDK Manager's active
SDK and its standard user directory under
`~/Library/Application Support/Garmin/ConnectIQ`.

Java 11 or later is required; local validation used Temurin 11. Set `CIQ_JAVA_HOME`
if necessary. No automatic Java, Rosetta or security setting changes are made.
SDK 9.2.0 includes simulator builds for arm64 and x86_64.

The first `make build-watch` creates `.local/keys/developer.der` using RSA with
4096 bits, PKCS#8 DER encoding and file permissions 0600. Existing keys are retained.
Use `CIQ_DEVELOPER_KEY` for an existing private key. Back it up privately; never
commit it or include it in a screenshot, issue, chat or source archive.

## Git publication hooks

```sh
make install-hooks
make check-secrets
make check-secrets-history
```

Hooks apply only to this repository clone. The commit hook checks staged blobs;
the push hook also checks reachable history. A new clone must install its hooks.
Do not override existing custom hooks without reviewing how they are combined.
See [security guidance](../SECURITY.md) before uploading files through a browser.

## Simulator

`make sim` builds and opens the app. Keep the desktop session unlocked. Initial
connection is retried at most three times. The interactive command runs until the
app exits; it is not stopped after 90 seconds. `make test-watch` keeps a bounded
runtime and requires the complete `PASSED (passed=N, failed=0, errors=0)` summary.
SDK 9.2.0 can return exit code 1 even with that successful summary; empty or failed
results are never treated as a pass.

GPS does not start on launch. Press START or DOWN, then explicitly load synthetic
GPS data through the simulator. Use `tests/fixtures/synthetic-walk.gpx` and Good
quality for a valid fix; Poor and Last Known are not fresh usable fixes. The app
always uses English, even if the simulator system language differs.

If Activity Data becomes locked after reloading during playback, quit and reopen
the simulator, then load the fixture again. Complete any macOS Keychain prompt
yourself; passwords are not read or recorded. End the test session afterward.

`make sim-offline` is a compatibility command for the same offline grid. Watch
builds read no `.env`, `.local/watch.json`, URL or token resources. No API, public
tunnel, phone or Garmin Connect is needed. Both START and DOWN open sessions without
recording. For physical installation and remaining acceptance checks use the
[field checklist](grid-field-test.md). Earlier raster setup remains in the
[archive](archive/raster-setup.md).
