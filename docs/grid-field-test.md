# Local only FieldGrid physical acceptance

Full acceptance: NOT RUN. Version 0.2.2 still showed 7 to 11 m stationary drift
with slight arm movement, according to the user. Version 0.2.3 installation and
identical readback PASS. The user confirms stationary hold and walking response:
that limited check is PASS. The broader checklist remains incomplete. Use the hash in
[latest evidence](evidence/wrist-motion/result.json). No recording or sync test is
required. Never publish real coordinates or sensor traces.

1. Install build/FieldMap.prg into GARMIN/Apps via MTP; read back and verify SHA-256.
   Do not remove user activities or change firmware, Bluetooth or sync settings.
2. Open FieldGrid G0: home starts no GPS. With phone disconnected, START opens grid;
   DOWN from home opens filtered coordinates; START toggles Raw and Filtered. Obtain GPS outdoors and inspect quality/age.
3. Check zoom, pan on both axes, recenter and day/night. Inspect coordinate label fit.
4. After a usable fix, stand still outdoors for five minutes. Check that Diagnostics
   reports Motion STILL or VERIFY, the marker stays fixed and distance stops increasing.
   Also turn the wrist slightly while keeping your feet still. Raw coordinates may vary; Filtered values should match the held marker. Note
   status, elapsed time and distance only, without recording real coordinates.
5. Walk slowly and normally, turn, then stop for two minutes and walk again. Check
   Motion GAIT/STEPS and movement response. Try a steady wrist as well as normal arm
   swing. If real movement is blocked, Diagnostics START disables assistance; report
   that result as a sensor acceptance failure, not a successful assisted walk.
   Compare a five minute stationary check with assistance on and off. Do not promise
   zero error from the GPS fallback. Test missing/weak GPS separately.
6. Inspect live time, distance, speed and pace. BACK pauses: time freezes, GPS and motion sampling stop.
   Resume continues with a gap. End session clears data and returns to home.
7. Test GPS loss, screen dimming and system hidden/foreground transitions separately.
   A GPS gap must not accumulate guessed distance or a straight connecting segment.
8. Run a two hour session. Record diagnostics heap/peak/trace and battery before/after;
   verify the 180-point bound, then End and reopen. No coordinates/history should remain.
9. Verify no new FIT activity, app data log, cache or Garmin Connect activity is
   created by FieldGrid. Existing Garmin health/activity records are outside its scope.

Record PASS, FAIL or NOT RUN with exact build hash, firmware and user observations.
No physical accuracy/battery/storage claim may be inferred from synthetic tests.
