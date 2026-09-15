# Wrist motion correction evidence

Version 0.2.3, Forerunner 165, SDK 9.2.0. Synthetic regression input only.

| Check | Result |
| :--- | :--- |
| v0.2.2 stationary field test | FAIL by user report: 7 to 11 m drift with slight arm movement; improved but unresolved |
| Baseline wrist/step regressions | 32 PASS, two assertion errors |
| Updated fr165 tests | 37 PASS |
| Python tests | 116 PASS; two existing dependency deprecation warnings |
| Production build | PASS, zero warnings, 126,620 bytes |
| Physical USB transfer | PASS; readback is identical |
| New physical stationary and walking checks | PASS by user report after installation |
| Physical battery and full G0/G3 | NOT RUN |

The updated classifier holds synthetic 11 m GPS drift during small wrist rotation,
isolated arm pulses and small vibration. Four hertz vibration is also rejected.
One native step every twenty seconds does not release the hold. Synthetic walking
and running rhythms from 0.6 to 2.8 Hz preserve movement; GPS speeds include 0.35,
0.65, 1.4 and 3.2 m/s. The original GPS quality, slow walk, gap, relocation, date
line, polar, trace, display and lifecycle tests continue to pass.

Sensor stress still processes 12,000 batches / 300,000 samples across twenty
start, pause, resume, inactive and stop loops. The final post stop test heap remains
within the 512 byte warm state bound. This is simulator test heap, not a battery
measurement. Sampling frequency and buffer limits are unchanged. Production size
increased by 1,360 bytes from v0.2.2. No session storage or transmission was added.

The English screen layout is unchanged apart from the version and short Motion
labels. The existing numeric/round screen rendering test passes in both themes;
new native screenshots and continuous hardware sensor delivery are not claimed.
Earlier [screenshots](../stationary-filter/README.md) are labeled as v0.2.2.

See [result](result.json), [watch output](watch-tests.txt),
[baseline failure](baseline-watch-tests.txt), [installation](physical-install.json),
[previous failure](v022-physical-result.json), [new physical pass](physical-user-check.json), [review](review.md) and
[ADR 009](../../decisions/009-wrist-motion-rejection.md).

## Commands

- `make test-watch` before correction: FAIL with two new assertion errors.
- `make test-watch` after correction: PASS, 37 tests, fr165 only.
- `make test`: PASS, 116 tests using .venv.
- `make build-watch`: PASS, zero warnings.
- OpenMTP transfer to GARMIN/Apps/FieldMap.prg and exact local readback: PASS.

No personal location, activity or sensor trace was collected. No firmware, account,
public service or global package installation changed. The user confirms that the position stays still when stationary and advances when
walking. This is a limited physical PASS; quantitative accuracy, battery and full
G0/G3 remain unverified.
