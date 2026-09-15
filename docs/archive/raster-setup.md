# Historical raster development setup

Use the [current setup](../setup.md) for FieldGrid. These instructions document the
former network application and do not enable map downloads in the current watch build.

## Isolated tools

`make setup` created `.venv` using an existing supported Python and the exact versions
in `requirements-dev.lock`. Runtime packages were in `requirements.lock` and direct
dependencies in `pyproject.toml`. No system Python, Homebrew, global Node or shell
startup modification was required. An existing unsupported virtual environment had
to be moved aside rather than silently reused.

The official SDK Manager supplied SDK 9.2.0 and the Forerunner 165 package. Local
validation placed the SDK at `/tmp/fr165-tools/sdk`; `.local/toolchain.json` stored
that private path. SDK Manager's font/device files remained in its standard user
folder under `~/Library/Application Support/Garmin/ConnectIQ`. Temporary tools can
be cleaned by macOS; a persistent SDK path can be supplied through `CIQ_SDK_HOME`.

Java was selected from the existing installation, optionally through `CIQ_JAVA_HOME`.
No automatic Rosetta, Java or system security changes were made. SDK 9.2.0 included
arm64 and x86_64 simulators. `make build-watch` created a 4096 bit RSA PKCS#8 DER key
at `.local/keys/developer.der`, permissions 0600, without replacing an existing key.
`CIQ_DEVELOPER_KEY` could select a separately managed key. Keys were never published.

## Former simulator behavior

The interactive simulator command ran until app exit, with at most three initial
connection attempts. Automated tests retained a timeout and required a complete
PASS summary even when SDK 9.2.0 returned its unusual exit code 1. GPS started only
after the user selected a session; fixtures were loaded explicitly. Good quality
was needed for a usable fix. Poor or Last Known did not imply fresh GPS.

A simulator reload during playback could leave Activity Data locked. Restarting the
simulator and loading the fixture resolved that state. Users completed their own
Keychain prompts; passwords were not collected. English UI was checked even with a
Turkish simulator language setting.

The former `make sim-offline` generated a separate offline binary, while `make sim`
used private raster configuration outside Git. That avoided stale Properties values
shadowing a new build. Current FieldGrid instead makes both commands local only and
removes all private raster resources.

## Former private HTTPS test

The Mac's localhost was not reachable as the Mac from an iPhone or Garmin image
converter. Real image downloads required valid reachable HTTPS. No command
implicitly authorized a tunnel or public deployment.

After a separate authorized origin decision, the former setup used:

```sh
.venv/bin/python scripts/dev_config.py --url https://your-test-origin.example
make api
```

Existing `.env` and `.local/watch.json` were preserved. Private changes needed both
origins to agree. The development token protected only the test renderer, not a
production account/pairing system. Credentials were not printed.

Hosting needed TLS termination, one API worker, bounded bodies, a log policy and
process restart handling. Uvicorn/reverse proxy logs could not contain Authorization,
query strings or complete signed image URLs. The API bound to loopback behind TLS.
A Mac tunnel stopped when the Mac slept and was not a permanent field solution.
See the [historical HTTPS plan](../https-simulator-test.md).

## Provider

`FR165_MAP_PROVIDER=openfreemap` selected the real provider without an upstream
API key; `synthetic` required explicit test selection. `FR165_PUBLIC_BASE_URL`
identified the project's raster converter, not OpenFreeMap. HTTPX and vector decoding
ran inside the Python environment on the server. No Python, tile cache or SDK was
included in the watch package. Current FieldGrid uses none of this service.
