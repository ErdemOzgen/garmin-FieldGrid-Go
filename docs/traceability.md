# Requirements and evidence

The [current requirements](../requirements.md) describe FieldGrid v0.2.3. The
[earlier raster overview](archive/raster-readme.md) is historical.
Implementation, simulator validation and physical acceptance are separate states.

| Requirement | Implementation | Evidence and remaining boundary |
| :--- | :--- | :--- |
| GRID01 | Explicit START or DOWN, one GPS subscription | Home and lifecycle tests; physical grid launch reported without error |
| GRID02–GRID03 | GridState and Geo, WGS84/Mercator, zoom 10–19, pan/follow | Projection, date line, polar and button tests; synthetic screenshots |
| GRID04–GRID05 | PositionFilter, MotionState and bounded GpsState trail | Stationary, slow walking, spikes, relocation and stress tests; v0.2.2 physical drift FAIL; v0.2.3 standing/walking PASS by user report |
| GRID06–GRID07 | GPS validation, quality, age and explicit Filtered / Raw coordinate modes | Invalid, stale, poor and missing fix tests; no internet permission |
| GRID08 | FieldSession clock, filtered distance, GPS speed and pace | Fresh speed gating and pause tests; native activity metrics are not claimed |
| GRID09–GRID10 | Pause/resume/end, inactive/active/exit cleanup | Forty GPS and twenty added sensor lifecycle cycles and button flow tests; physical interruption/endurance remains NOT RUN |
| GRID11 | English resources, native fonts, day/night screens | Round 390 × 390 layout test and reviewed simulator images |
| GRID12 | Version, RAM, trace, GPS and filter counters | Diagnostic screenshot; no private coordinate or token output |
| Privacy | Positioning and Sensor permissions; no recorder/network/persistence writer | Static watch contract tests; no new FIT or app data writes |
| Publication | Ignore rules, source/index/history scans, hooks, CI and source ZIP | Adversarial publication tests and release evidence |

The latest watch build passed 37 simulator tests. Version 0.2.3 USB transfer and
exact readback passed on the physical Forerunner 165. The user confirms stationary position holds and walking advances in v0.2.3.
Quantitative GPS accuracy and long duration battery remain unmeasured. The previous v0.2.1 grid launch
passed, but stationary drift failed by user report. Full G0/G3 is not passed.
See [current evidence](evidence/wrist-motion/README.md).

Original raster requirements FR10–FR25, attribution FR30–FR31, routes/FIT FR32–FR38
and optional map packages OF01–OF04 are superseded for this product by ADR 007.
Original NFR targets remain historical targets, not measured results or permission
to reintroduce recording. A one second redraw does not prove the original 500 ms
p95 latency target. A reported SDK memory limit is distinct from measured device use.
