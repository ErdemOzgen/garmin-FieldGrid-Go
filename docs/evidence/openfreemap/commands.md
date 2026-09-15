# Commands and scope

14 September 2026. Commands ran in the project; Python packages only in `.venv`.

| Command / check | Result | Record |
|---|---|---|
| `make test` | PASS, 89 tests, 96% coverage, 2 upstream deprecations | `python-tests.txt` |
| `make build-watch` | PASS, fr165, zero warnings | `watch-build.txt`; ../automated.json |
| `make test-watch` | PASS, 21 tests | `watch-tests-final.txt` / .json |
| `.venv/bin/pip-audit --disable-pip --no-deps -r requirements.lock -f json` | No known vulnerabilities | `dependency-audit.json` |
| `.venv/bin/python -m pip check` | No broken requirements | observed terminal output; cache disabled by sandbox |
| `make contracts` | PASS | ../../../contracts/openapi.json |
| Real HTTP smoke, `scripts/api.py` subprocess | Six profiles PASS; 401 unauthorized; API stopped | `http-smoke.json` |
| `make evidence` | Current source/artifact checks PASS; physical NOT RUN | ../automated.json |
| `make package` + extracted source pytest/build | PASS, 89 tests, fresh key/config, fr165 build | `package-python-tests.txt`, `package-fr165-build.txt`, `../source-package.json` |
| `git diff --check`, `make check-secrets` | PASS | observed terminal output |

The HTTP smoke used a private local helper to start the loopback API, send the
fixed Utrecht fixture and retrieve each signed PNG; secrets and signed URLs were
not printed or published. No public tunnel was opened for this extension.
The watch tests return raw SDK exit code 1 even with Garmin's explicit PASSED
summary; the existing runner validates the complete summary and records both.
Earlier English round width failures were corrected and the final full run passed.
