import Toybox.Math;
import Toybox.Position;
import Toybox.Lang;

// In-memory display filter; its coordinates are never recorded or transmitted.
class PositionFilter {
    var xy as Array or Null = null;
    var samples as Array;
    var head = 0;
    var count = 0;
    var moving = false;
    var slow = 0;
    var fast = 0;
    var outliers = 0;
    var outlier as Array or Null = null;
    var status = "WAIT";
    var rebased = false;
    var motionOrigin as Array or Null = null;
    var previousCandidate as Array or Null = null;
    var motionPath = 0.0;
    var motionSeconds = 0;

    function initialize() { samples = new [3]; }
    function median(a, b, c) { return Geo.max(Geo.min(a, b), Geo.min(Geo.max(a, b), c)); }
    function clearMotion() { motionOrigin = null; motionPath = 0.0; motionSeconds = 0; fast = 0; }
    function reset(point as Array) {
        xy = [point[0], point[1]]; count = 0; head = 0;
        moving = false; slow = 0; fast = 0; outliers = 0; outlier = null; status = "HOLD";
        previousCandidate = null; clearMotion();
    }
    function update(raw as Array, latitude, speed, quality, dt, gap, motionHint) as Array {
        rebased = gap || xy == null;
        if (rebased) { reset(raw); }
        var point = [xy[0] + Geo.wrapX(raw[0] - xy[0]), raw[1], speed];
        // Large relocation requires three consistent fixes; never draw a teleport.
        if (motionHint != false && Geo.distance(point, xy, latitude) > 40 + 15 * dt) {
            outliers = outlier != null && Geo.distance(point, outlier, latitude) < 15 ? outliers + 1 : 1;
            outlier = point; status = "REACQUIRE";
            if (outliers < 3) { return xy; }
            reset(point); rebased = true;
        } else { outliers = 0; outlier = null; }
        samples[head] = point; head = (head + 1) % 3; count = Geo.min(3, count + 1);
        if (count < 3) { return xy; }
        var a = samples[0] as Array; var b = samples[1] as Array; var c = samples[2] as Array;
        var candidate = [median(a[0], b[0], c[0]), median(a[1], b[1], c[1])];
        var d = Geo.distance(candidate, xy, latitude);
        // An isolated speed spike must not release a stationary position.
        var knownSpeed = Geo.finite(a[2]) && Geo.finite(b[2]) && Geo.finite(c[2]);
        var filteredSpeed = knownSpeed ? median(a[2], b[2], c[2]) : null;
        var step = previousCandidate == null ? 0 : Geo.distance(candidate, previousCandidate, latitude);
        previousCandidate = candidate;
        slow = !knownSpeed && step < 0.25 * dt ? Geo.min(3, slow + 1) : 0;
        // Low measured speed takes priority over displacement, including wide drift.
        if (motionHint == false || (knownSpeed && filteredSpeed < 0.25) || (!knownSpeed && slow >= 3)) {
            moving = false; clearMotion(); status = "HOLD"; return xy;
        }
        var radius = quality == Position.QUALITY_GOOD ? 4.0 : 7.0;
        if (!moving) {
            // A bounded window measures new motion, not offset from a drifting fix.
            // With no speed, require sustained directional progress; GPS alone
            // cannot distinguish every coherent drift from genuine slow movement.
            if (motionOrigin == null || motionSeconds + dt > 12) {
                clearMotion(); motionOrigin = candidate;
            } else { motionSeconds += dt; motionPath += step; }
            fast = knownSpeed && filteredSpeed >= 0.30 ? Geo.min(3, fast + 1) : 0;
            var net = Geo.distance(candidate, motionOrigin, latitude);
            var coherent = motionPath > 0 && net / motionPath >= 0.8;
            var confirmed = knownSpeed ? fast >= 3 && net >= radius / 2 :
                motionSeconds >= 5 && net >= radius && net >= 0.25 * motionSeconds;
            if (!confirmed || !coherent) { status = "HOLD"; return xy; }
            moving = true;
            // A held location can be far from a new GPS baseline. Do not charge
            // that stationary offset as walking distance when motion resumes.
            var allowance = radius + (knownSpeed ? filteredSpeed * 2 : 0);
            if (d > net + allowance) { xy = candidate; rebased = true; }
            clearMotion();
        }
        if (moving && d >= 0.6) {
            var alpha = dt / (1.0 + dt);
            xy = [xy[0] + (candidate[0] - xy[0]) * alpha, xy[1] + (candidate[1] - xy[1]) * alpha];
        }
        status = moving ? "MOVING" : "HOLD";
        return xy;
    }
}
