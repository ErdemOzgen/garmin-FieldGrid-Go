# Critical findings

None remaining in the historical synthetic G0 scope. This review is historical;
use [the current grid review](wrist-motion/review.md) for the installed application.
Trust boundaries, correctness/evidence and operational recovery were reviewed separately.

# Important findings

- Physical POC02/04/08 were NOT RUN at this point. Simulator GPS, transfers and
  battery assumptions could not establish physical G0/G3 acceptance.
- The initial renderer generated synthetic maps only. Real roads/paths required a
  later licensed provider decision and integration; the README disclosed that limit.

# Minor findings

- The SDK lived in a temporary directory. Doctor reported missing tools after cleanup;
  a configured persistent SDK path was available without installing system packages.
- Two upstream Python deprecation warnings remained for future lock maintenance.
  They were not watch runtime failures.

# Open questions

Physical firmware/iOS/GCM, graphics/heap cost, locked phone behavior, bitmap persistence
and hosting/provider decisions needed evidence. They were not classified as proven bugs.

# Recommended corrections

Implemented with regressions: permanent 401 could not be retriggered by panning;
invalid Unicode Authorization/signature returned controlled 401/403; oversized bodies
were rejected before another buffer copy; stale callbacks could not release a new
job; source and artifact hashes were checked together.

A second pass reviewed String equality, unsupported graphics APIs, geographic image
matching, publication boundaries and key leakage. One G0 test token was never
presented as production identity or a hidden implementation of G2 pairing.

The later simulator review covered 56 Python tests, 17 watch tests in two languages,
six HTTPS raster transfers, outage recovery, GPS quality loss and a small Storage
round trip. ADR 003 records coordinate precision, stale Properties, large Storage
OOM, image counting, clipping and theme corrections. Historical FAIL results remain.
The final English BACK label had separate source identity from the earlier network run.

Empty offline raster configuration caused expected resource warnings in that old
binary; the active HTTPS binary compiled without warnings. A 1K storage pass did
not prove total capacity, bitmap or reboot behavior. Peak heap was sampled once per
second, not a physical instantaneous maximum. The authorized tunnel closed before
30 minutes and private settings were restored.
