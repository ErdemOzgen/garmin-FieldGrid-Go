import Toybox.Lang;
import Toybox.Math;

// Motion evidence only. Never integrate acceleration into coordinates or distance.
// The sensor callback owns its arrays; keep only bounded scalar summaries in RAM.
class MotionState {
    var enabled = true;
    var sampledMs = null;
    var gaitMs = null;
    var stepMs = null;
    var previousSteps = null;
    var stepWindowMs = null;
    var stepCredits = 0;
    var stillBatches = 0;
    var unavailable = false;
    var magnitudeMean = 1000.0;
    var abovePeak = false;
    var lastPeakMs = null;
    var cadenceMs = null;
    var rhythmCount = 0;

    function clear() {
        clearAcceleration(); stepMs = null; previousSteps = null;
        stepWindowMs = null; stepCredits = 0;
        stillBatches = 0; unavailable = false;
    }
    function clearAcceleration() {
        sampledMs = null; gaitMs = null; stillBatches = 0;
        magnitudeMean = 1000.0; abovePeak = false; lastPeakMs = null;
        cadenceMs = null; rhythmCount = 0;
    }
    function steps(value, nowMs) {
        if (!enabled || !Geo.finite(value) || value < 0) {
            previousSteps = null; stepMs = null; stepWindowMs = null; stepCredits = 0; return;
        }
        // Midnight and missing values establish a fresh baseline, not a step event.
        if (previousSteps != null && value > previousSteps) {
            if (!recent(stepWindowMs, nowMs, 6000)) { stepWindowMs = nowMs; stepCredits = 0; }
            stepCredits = Geo.min(3, stepCredits + value - previousSteps);
            if (stepCredits >= 3) {
                stepMs = nowMs; stepWindowMs = null; stepCredits = 0;
            }
        }
        if (previousSteps != null && value < previousSteps) {
            stepMs = null; stepWindowMs = null; stepCredits = 0;
        }
        previousSteps = value;
    }
    function peak(nowMs) {
        var interval = lastPeakMs == null ? null : nowMs - lastPeakMs;
        var valid = interval != null && interval >= 300 && interval <= 2000;
        var consistent = valid && (cadenceMs == null || Geo.abs(interval - cadenceMs) <= Geo.max(180, cadenceMs * 0.45));
        rhythmCount = consistent ? Geo.min(3, rhythmCount + 1) : 0;
        if (!consistent) { gaitMs = null; }
        if (rhythmCount >= 3) { gaitMs = nowMs; }
        cadenceMs = valid ? interval : null; lastPeakMs = nowMs;
    }
    function sample(x as Array or Null, y as Array or Null, z as Array or Null, nowMs) {
        if (!enabled || x == null || y == null || z == null || x.size() < 5 ||
            x.size() != y.size() || x.size() != z.size() || x.size() > 25) {
            clearAcceleration(); return;
        }
        var continuous = sampledMs != null && nowMs > sampledMs && nowMs - sampledMs <= 1500;
        if (!continuous) { clearAcceleration(); }
        var mean = 0.0; var variance = 0.0;
        for (var i = 0; i < x.size(); i++) {
            if (!Geo.finite(x[i]) || !Geo.finite(y[i]) || !Geo.finite(z[i]) ||
                Geo.abs(x[i]) > 16000 || Geo.abs(y[i]) > 16000 || Geo.abs(z[i]) > 16000) {
                clearAcceleration(); return;
            }
            // Vector magnitude is invariant under rotation of gravity. Axis
            // variance alone incorrectly treated a small wrist turn as travel.
            var magnitude = Math.sqrt(x[i].toFloat() * x[i] + y[i].toFloat() * y[i] + z[i].toFloat() * z[i]);
            var delta = magnitude - mean; mean += delta / (i + 1);
            variance += delta * (magnitude - mean);
            magnitudeMean += 0.08 * (magnitude - magnitudeMean);
            var signal = magnitude - magnitudeMean;
            if (!abovePeak && signal >= 45) {
                peak(nowMs - (x.size() - 1 - i) * 40); abovePeak = true;
            } else if (signal <= -15) { abovePeak = false; }
        }
        variance /= x.size();
        if (mean < 500 || mean > 1500) {
            clearAcceleration(); return;
        }
        stillBatches = variance < 324 ? (continuous ? Geo.min(4, stillBatches + 1) : 1) : 0;
        sampledMs = nowMs; unavailable = false;
    }
    function recent(value, nowMs, limit) { return value != null && nowMs >= value && nowMs - value <= limit; }
    function hint(nowMs) {
        if (!enabled) { return null; }
        if (recent(stepMs, nowMs, 4000)) { return true; }
        if (!recent(sampledMs, nowMs, 2500)) { return null; }
        // Four rhythmic peaks, not a single arm gesture. Fresh ambiguous input
        // keeps the GPS hold; only absent/invalid/stale input uses GPS fallback.
        return recent(gaitMs, nowMs, 2200);
    }
    function label(nowMs) {
        if (!enabled) { return "OFF"; }
        var value = hint(nowMs);
        if (value == null) { return unavailable ? "UNAVAILABLE" : "WAIT"; }
        if (value) { return recent(stepMs, nowMs, 4000) ? "STEPS" : "GAIT"; }
        return stillBatches >= 4 ? "STILL" : "VERIFY";
    }
}
