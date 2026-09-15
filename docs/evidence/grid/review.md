# Critical findings

None found in the reviewed grid/filter/session implementation. This is a local
code review, not a physical safety or fitness certification.

# Important findings

- **Product constraint, pending decision:** automatic deletion of saved FIT files
  after successful sync cannot be implemented with the documented Connect IQ SDK.
  Session.discard completes an unfinished recording; it does not remove a saved
  activity. No completed sync callback exists here. Preserve the user's data and
  block watch deployment until recording/manual deletion vs no recording is chosen.
- **Physical evidence gap:** new grid filtering, native FIT sync, background behavior,
  actual device storage and battery are NOT RUN. Prior raster tests do not pass them.

# Minor findings

None remaining. Review corrections included readable grid labels, an explicit REC
indicator, quality labels, and ensuring displayed peak heap is at least the current
sample. Grid preferences were removed following the user's stricter storage request.

# Open questions

- Does the user retain native FIT recording with manual deletion after verified
  Garmin Connect sync, or require no activity file at all?
- What are the physical drift, walking delay, battery and saved FIT size over a
  two hour session? These require the exact new build and user/device evidence.

# Recommended corrections

Completed: remove watch network/bitmap code and private build resources; bound trace
and filter state; retain unsaved recording handles on API failure; confirm Discard;
release GPS/timers on finish; remove application persistence and known old keys;
show stale/reacquiring state; distinguish native FIT metrics from the display filter.

Regression checks cover failures, slow movement, stop/start, single and sustained
jumps, data loss gaps, poles/date line, repeated redraws and repeated GPS lifecycle.
A second review checked no network imports, no application Storage.setValue calls,
resource paths inside the watch project, no guessed coordinates and no automatic
claim that phone connectivity proves sync. No destructive activity cleanup was added.
