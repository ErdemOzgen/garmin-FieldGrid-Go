# Review of stationary filtering and sensor support

The low speed hold was being overridden by a displacement check. The new failing
baseline demonstrates the defect independently of coordinate display precision.
The correction takes low speed and fresh stillness evidence before motion release,
then requires bounded directional progress. A rebase excludes accumulated held
error instead of charging it as walking distance. Raw coordinates remain available
and the view clearly identifies the filtered alternative.

MotionState retains scalar summaries only. Sensor input arrays are validated,
processed once and discarded; no sensor history, integration, activity recording
or new persistence is introduced. The daily step total is used only as a local
baseline. Missing data is unknown, never a fabricated zero movement measurement.
Lifecycle tests execute real SDK register/unregister methods and verify repeated
pause, resume, inactivity, toggle and end. Synthetic batches exercise the classifier.

The model does not reconstruct Garmin's proprietary fusion. GPS drift with
plausible speed and wrist motion can still pass. A very steady wrist can suppress
real motion; the Diagnostics toggle and step evidence reduce that limitation but
do not eliminate it. Step latency is unspecified. Stale or missing sensors revert
to the GPS filter. Confirmed large relocation and fresh acquisition after a GPS gap
can change displayed location while adding no distance. Six decimals do not imply
centimeter accuracy. Physical battery cost and sensor delivery need real testing.

Public documentation reflects the added Sensor permission and distinguishes the
old physical stationary failure from new untested physical behavior. Screen layout
checks pass; interactive continuous simulator data delivery remains unverified and
is not described as a PASS. The installed binary was read back exactly. No personal
activity files were opened or changed. The source package remains separate from
private keys, SDK, .venv, local configuration and device readback files.
