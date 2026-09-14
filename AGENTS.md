# Working agreement

- Read `requirements.md`, `docs/progress.md` and the decisions before editing.
- This delivery is G0. Do not mark G0/G3 passed without physical Forerunner 165 and iPhone evidence. PASS, FAIL and NOT RUN are distinct.
- Use `.venv` for Python. No global package installs, SDK copies in Git, firmware changes, credentials or real GPS traces in source control.
- Verify Monkey C APIs against the installed SDK; compile with `make build-watch` for Forerunner 165. Its verified SDK device ID is `fr165` (see ADR 001). Another device model is not an acceptable substitute.
- GPS starts only after explicit user action. Never silently replace real GPS with simulated coordinates. Label all synthetic content.
- Keep map image and metadata atomic, reject obsolete responses, bound trace/cache/network resources, preserve GPS during network errors.
- Run `make test`, `make build-watch`, `make test-watch` when possible; record commands, failures and limitations in `docs/evidence` and update `docs/progress.md`.
- No paid provider, public deployment, store publishing or account changes without the user's authorization. Routine local implementation and fixes are authorized.
