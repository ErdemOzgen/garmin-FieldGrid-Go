# Security and publication

## Current watch application

FieldGrid v0.2.3 processes location only after the user presses START or DOWN.
Its permissions are Positioning and Sensor. It makes no network request, records no FIT
activity, sends no session data to a phone and writes no new application data.
Session coordinates, trace, motion summaries and live metrics are released on end
or exit. The accelerometer and step count are processed in memory only; no daily
step total or sensor trace is saved or transmitted.

Only three obsolete app preference keys are removed during upgrade. Existing
Garmin activities and the watch's independent health sync settings are untouched.
Screenshots in the README use synthetic simulator locations.

## Private files

Keep signing keys in `.local/keys` and private evidence in
`docs/evidence/private/`. `.env` and `.local/watch.json` belong only to the historical
raster experiment. Current watch builds do not read or embed those credentials.
No account or API key is needed for the grid application.

`.gitignore` excludes environment variants, credential files, key containers,
SDKs, virtual environments, build outputs, archives, logs, databases, personal
photos and device activity exports. `tests/fixtures/synthetic-walk.gpx` is the
single reviewed GPX exception. `.env.example` contains placeholders only.

## Publication checks

- `make check-secrets` checks publishable working files against prohibited paths,
  private key markers, common provider token formats, JWTs, credentials in URLs,
  suspicious secret assignments and known values from private local configuration.
- `make check-secrets-history` checks every reachable commit and tag, including
  content later deleted. Existing Git history can leak data even if HEAD is clean.
- `make install-hooks` enables repository hooks for this clone. The commit hook
  scans the actual Git index, so a clean working copy cannot hide a staged secret.
  The push hook checks working files and reachable history before transmission.
- GitHub Actions repeats working file and full history checks. CI is a later
  detection layer; it cannot prevent the first upload of a secret.
- `make package` runs the publication guard before creating the source archive.
  Symlinks and submodules are refused to avoid unaudited external content.

Failures print paths and finding categories, never matched secret values. The
reserved `user:pass` example at `maps.example` is an exact negative test fixture;
other credentials or hosts are not exempt. Security tests generate dummy values
inside temporary directories instead of committing realistic credential strings.

Ignore rules do not remove files already tracked. They also do not apply to browser
uploads. Use Git with the installed hooks, or extract the source archive and upload
its contents. Do not upload the entire local working directory using a file picker.
Hooks can be bypassed and custom scanners cannot recognize every possible secret.
Review changes before publishing; no tool can promise that arbitrary credentials
or private information will always be detected. No GitHub account setting, remote,
store listing or public deployment is changed by these local checks.

## If a secret is discovered

Stop publication. Revoke or rotate an exposed credential with its provider. Remove
it from current source and review whether reachable Git history also contains it.
Do not assume that adding `.gitignore` or deleting the latest copy repairs history.
History rewriting and remote cleanup require coordination with the repository owner.
Never paste secrets, real GPS traces or private image URLs into a public issue.

## Historical raster service

The old Python renderer requires a reachable HTTPS origin for Garmin image
conversion. A development token protects that service; it is not an OpenFreeMap
API key. Its signed image grants expire after 120 seconds. Access logs exclude
coordinates and credentials, input sizes and caches are bounded, TLS is verified,
and arbitrary provider URLs are rejected. This service is unused by FieldGrid.
Public tunnels, hosted services, paid providers and account changes require explicit
authorization. Historical experiments do not authorize a new deployment.

Dependencies are pinned. `make audit` checks the runtime lock. Security contact and
any GitHub security reporting channel must be selected by the owner when publishing.
