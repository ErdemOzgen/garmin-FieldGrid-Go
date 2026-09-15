# Historical raster field checklist

This checklist describes the former map application. Use the
[current grid checklist](grid-field-test.md) for FieldGrid. Simulator evidence and
physical results are separate; missing physical observations cannot pass G0.

## Simulator review

1. The former offline command tested screen/GPS without network. Full PNG transfer
   needed the separately authorized [HTTPS plan](https-simulator-test.md), since the
   external Garmin converter could not fetch localhost images.
2. Confirm English UI and no GPS before explicit START or DOWN. The former START
   opened maps; DOWN opened coordinates without map requests.
3. Explicitly load `tests/fixtures/synthetic-walk.gpx`, use the playback triangle
   rather than Data Field Timer Start, and set GPS quality to Good. Longer generated
   data was available through `.venv/bin/python scripts/synthetic_walk.py`.
4. Inspect marker, trace, age, visible attribution and English labels at 390 px.
   Test three zooms, both themes, 195/256/390 rasters and pan axes; BACK recentered.
5. Stop the API and check continuing GPS, separate network status and recovery after
   restart. End the session after testing.

The SDK could reject loopback HTTP with -1001 under device HTTPS requirements.
Any temporary simulator adjustment applied only to the approved loopback experiment;
normal and physical use retained HTTPS. A reload during GPS playback sometimes
required closing/reopening the simulator and loading the fixture again.

## Historical physical installation

Build only `fr165`, copy the PRG rather than its debug companion, and connect with a
USB data cable. OpenMTP 3.3.0 arm64 in Kalam mode was validated from `/tmp`, without a
system installation. If the device showed only charging despite MTP selection, a
normal power cycle and reconnect resolved earlier transfer failures. This was not
a factory reset or firmware change. Do not delete personal files.

Copy the app to `GARMIN/Apps`, disconnect and open it. The former FieldMap START
required reachable HTTPS for maps; DOWN offered offline coordinates. Current
FieldGrid has no map download or server requirement.

## Evidence fields

Record artifact/source digest, SDK/device version, firmware, iPhone/iOS/GCM if
relevant, brightness, always on, GPS mode, temperature, duration, battery before/after,
heap/peak, image size, error code, recovery and PASS/FAIL/NOT RUN. Do not publish real
coordinates, private URLs or identifiers. A home screen alone was not raster acceptance.

## Historical phone profiles

H01: locked phone/GCM background for at least 30 minutes and all raster sizes.
H02: another phone app open. H03: GCM force closed, without assuming success.
H04: internet off, Bluetooth on. H05: outside Bluetooth range and return.
H06: weak GPS, quality/age and trace gap. H07: dimming, inactive and exit behavior.
H08: device/phone restart and fresh GPS.

Begin with a 20–30 minute walk and then two hours of endurance. Battery NFR09 needed
at least three matched reference sessions. Latency targets needed 300 GPS events,
100 button actions, 20 first maps and 100 area changes. Single observations could
not establish p95 or full resource acceptance.

The old Storage probe wrote/read/compared/deleted 1024 ASCII characters. A larger
attempt had caused uncaught OOM, so it was removed from the live menu. That 1K pass
was not total capacity, bitmap persistence or restart evidence. The current grid
has no probe and no new persistent writes.

In offline coordinate checks, Poor quality retained the last coordinate and increased
age; Good recovered a fresh fix. Network Images remained zero. Review of any real
screen or trace was optional and required removing private information before sharing.
