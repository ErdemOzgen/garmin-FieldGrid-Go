"""Adversarial publication cases use generated dummy credentials in temporary repos."""

import json
import os
import subprocess
from pathlib import Path

import pytest

from scripts import check_secrets as scan


def git(root, *args):
    env = dict(
        os.environ,
        GIT_AUTHOR_NAME="Test",
        GIT_AUTHOR_EMAIL="test@example.invalid",
        GIT_COMMITTER_NAME="Test",
        GIT_COMMITTER_EMAIL="test@example.invalid",
    )
    return subprocess.run(["git", *args], cwd=root, env=env, capture_output=True, check=True)


@pytest.fixture
def repo(tmp_path):
    git(tmp_path, "init")
    return tmp_path


@pytest.mark.parametrize(
    "name",
    [
        ".env.production",
        ".local/watch.json",
        "build/app.PRG",
        "signing.P12",
        "credentials.json",
        "walk.GPX",
        "photo.HEIC",
        "cache.sqlite-wal",
    ],
)
def test_forced_staging_cannot_bypass_ignore_rules(repo, name):
    path = repo / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("{}")
    git(repo, "add", "-f", name)
    bad, _ = scan.check(repo, "staged")
    assert any(item[0] == name and "prohibited artifact" in item[1] for item in bad)


def test_staged_blob_is_scanned_even_when_working_copy_is_clean(repo):
    path = repo / "settings.txt"
    dummy = "ghp_" + "A1b2" * 10
    path.write_text(dummy)
    git(repo, "add", "settings.txt")
    path.write_text("safe working copy")
    assert not scan.check(repo, "working")[0]
    bad, _ = scan.check(repo, "staged")
    assert bad == [("settings.txt", "GitHub token")]
    assert dummy not in repr(bad)


def test_deleted_secret_is_found_in_history(repo):
    path = repo / "notes.txt"
    path.write_text("AKIA" + "A1" * 8)
    git(repo, "add", ".")
    git(repo, "commit", "-m", "Synthetic secret fixture")
    git(repo, "rm", "notes.txt")
    git(repo, "commit", "-m", "Remove fixture")
    assert not scan.check(repo, "staged")[0]
    assert scan.check(repo, "history")[0] == [("notes.txt", "AWS access key")]


def test_known_local_token_is_detected_without_provider_prefix(repo):
    dummy = "dummy" + "0123456789abcdefghijk"
    (repo / ".gitignore").write_text(".local/\n.env*\n")
    (repo / ".local").mkdir()
    (repo / ".local/watch.json").write_text(json.dumps({"nested": {"apiKey": dummy}}))
    (repo / "public.txt").write_text("Copied by mistake: " + dummy)
    bad, _ = scan.check(repo)
    assert bad == [("public.txt", "local credential value")]


def test_environment_variants_are_checked_for_known_values(repo):
    dummy = "dummy" + "9876543210abcdefghijk"
    (repo / ".gitignore").write_text(".env*\n")
    (repo / ".env.production").write_text('SERVICE_TOKEN="' + dummy + '"\n')
    (repo / "readme.txt").write_text(dummy)
    assert scan.check(repo)[0] == [("readme.txt", "local credential value")]


@pytest.mark.parametrize(
    "prefix,body",
    [
        ("AIza", "a1B2" * 8 + "a1B"),
        ("xoxb-", "a1B2" * 8),
        ("sk_live_", "a1B2" * 8),
        ("sk-proj-", "a1B2" * 12),
        ("hf_", "a1B2" * 8),
    ],
)
def test_provider_patterns(prefix, body):
    assert scan.findings((prefix + body).encode())


def test_generic_assignment_and_private_key():
    dummy = "aB3dE6gH9jK2mN5pQ8sT1vW4"
    assert "possible secret assignment" in scan.findings(('api_key="' + dummy + '"').encode())
    assert "private key" in scan.findings(("-----BEGIN " + "ENCRYPTED PRIVATE KEY-----").encode())


def test_reserved_fixture_does_not_exempt_other_credentials():
    fixture = "https://" + "user:pass@maps.example"
    assert not scan.findings(fixture.encode())
    assert scan.findings(fixture.replace("pass", "realpassword").encode())
    assert scan.findings(fixture.replace("maps.example", "maps.example.com").encode())


def test_symlink_cannot_export_files_outside_source(repo, tmp_path):
    (repo / "link.txt").symlink_to(tmp_path / "missing-private-file")
    assert scan.check(repo)[0] == [("link.txt", "symlink or submodule cannot be audited")]


def test_source_archive_mode_omits_private_outputs(tmp_path):
    (tmp_path / ".env").write_text("unused")
    (tmp_path / "build").mkdir()
    (tmp_path / "build/app.prg").write_bytes(b"binary")
    (tmp_path / "README.md").write_text("Public documentation")
    assert [p.name for p in scan.source_files(tmp_path)] == ["README.md"]
    assert not scan.check(tmp_path)[0]


def test_reviewed_synthetic_gpx_is_the_only_allowed_route():
    assert not scan.prohibited("tests/fixtures/synthetic-walk.gpx")
    assert scan.prohibited("tests/fixtures/real-walk.gpx")


def test_gitignore_covers_private_artifacts(repo):
    source = Path(__file__).resolve().parents[1] / ".gitignore"
    (repo / ".gitignore").write_bytes(source.read_bytes())
    for name in [
        ".env.production",
        ".local/keys/developer.der",
        "signing.pem",
        "signing.P12",
        "build/FieldMap.prg",
        "dist/release.zip",
        "walk.GPX",
        "photo.HEIC",
    ]:
        assert git(repo, "check-ignore", name).returncode == 0
