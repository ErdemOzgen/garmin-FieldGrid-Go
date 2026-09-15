# Critical findings

None in the verified local changes. Physical acceptance is still incomplete.

# Important findings

Resolved: MotionState previously treated axis variance as travel evidence and
returned unknown for fresh ambiguous input. Both could release a held location
while standing still. Baseline regressions reproduce wrist motion and isolated
step increments causing false distance. Magnitude based cadence confirmation,
multiple native steps and a hold during fresh unconfirmed input correct those
synthetic cases. All original regression checks continue to pass.

Remaining evidence boundary: periodic arm movement and delayed native steps may
still resemble travel when GPS also reports plausible motion. Tests cannot prove
universal rejection or Garmin native equivalence. Record the physical stationary
result separately; keep Motion source labels and the assistance toggle available.

# Minor findings

The current requirements header was still 0.2.1 although its body described the
0.2.2 behavior. The header and active document links now identify v0.2.3. Prior
physical pending entries now record the user's 7 to 11 m stationary failure.

# Open questions

The Motion label during the reported v0.2.2 drift is unknown. The user confirms
v0.2.3 now holds position when stationary and advances when walking. Quantitative
startup delay, unusual wrist postures and active sensor battery cost remain unmeasured. A sensor that provides no valid batches continues using GPS;
that fallback retains GPS ambiguity.

# Recommended corrections

The implementation retains Positioning and Sensor only, scalar motion summaries,
three GPS samples, 180 trace points and existing resource cleanup. Invalid batches
reset cadence state; sensor gaps cannot assemble a false rhythm across missing
data. Native step baselines reset at midnight and missing values. No activity
recorder, history writer, phone API or acceleration based dead reckoning is added.

The requested standing and walking field check passed by user report. Keep this
limited result separate from full G0/G3 and do not infer battery endurance.
If a legitimate activity is suppressed, the existing Diagnostics toggle provides
GPS filtering without requiring a new build or persisting preferences.
