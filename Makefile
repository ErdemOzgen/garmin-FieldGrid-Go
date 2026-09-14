PYTHON ?= python3
VENV := .venv/bin/python

.PHONY: setup doctor test lint format build-watch test-watch sim api evidence audit check-secrets contracts fixtures dev-config package

setup:
	$(PYTHON) -c 'import sys; sys.exit(0 if (3, 12) <= sys.version_info[:2] < (3, 15) else "Python 3.12-3.14 required. Use make setup PYTHON=/path/to/python3.14")'
	@if [ -x .venv/bin/python ]; then .venv/bin/python -c 'import sys; sys.exit(0 if (3, 12) <= sys.version_info[:2] < (3, 15) else "Existing .venv uses an unsupported Python. Move it outside the source tree and rerun setup.")'; fi
	$(PYTHON) -m venv .venv
	$(VENV) -m pip install --no-cache-dir -r requirements-dev.lock

doctor:
	$(PYTHON) scripts/watch.py doctor

lint:
	.venv/bin/ruff check services scripts tests
	.venv/bin/ruff format --check services scripts tests

format:
	.venv/bin/ruff format services scripts tests
	.venv/bin/ruff check --fix services scripts tests

test: lint check-secrets
	$(VENV) -m pytest --cov=services.api --cov-report=term-missing --junitxml=build/pytest.xml

build-watch:
	$(PYTHON) scripts/watch.py build

test-watch:
	$(PYTHON) scripts/watch.py test

sim:
	$(PYTHON) scripts/watch.py sim

api:
	$(VENV) scripts/api.py

contracts:
	$(VENV) scripts/contracts.py

fixtures:
	$(VENV) scripts/fixtures.py

dev-config:
	$(VENV) scripts/dev_config.py --simulator

evidence:
	$(VENV) scripts/evidence.py

audit:
	.venv/bin/pip-audit --disable-pip --no-deps -r requirements.lock

check-secrets:
	$(PYTHON) scripts/check_secrets.py

package:
	$(VENV) scripts/package.py
