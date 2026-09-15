import Toybox.Position;
import Toybox.Lang;

class GpsState {
    var lat = null;
    var lon = null;
    var xy as Array or Null = null;
    var quality = Position.QUALITY_NOT_AVAILABLE;
    var fixUtc = null;
    var receivedMs = null;
    var initialAge = 0;
    var speed = null;
    var motionHint = null;
    var filter as PositionFilter;
    var trace as Array;
    var count = 0;
    var head = 0;
    var gap = true;
    var distance = 0.0d;
    const CAPACITY = 180;

    function initialize() { trace = new [CAPACITY]; filter = new PositionFilter(); }
    function age(nowMs) {
        if (receivedMs == null) { return null; }
        var elapsed = (nowMs - receivedMs) / 1000.0;
        return elapsed < 0 ? 9999 : initialAge + elapsed;
    }
    function usable(nowMs) {
        var a = age(nowMs);
        return a != null && a <= 5 &&
            (quality == Position.QUALITY_GOOD || quality == Position.QUALITY_USABLE);
    }
    function accept(newLat, newLon, utc, q, newSpeed, nowUtc, nowMs) {
        var wasUsable = usable(nowMs);
        quality = q;
        if (!Geo.validGps(newLat, newLon) || !Geo.finite(utc) || utc <= 0 || utc > nowUtc + 2 ||
            (q != Position.QUALITY_GOOD && q != Position.QUALITY_USABLE) || nowUtc - utc > 5) {
            gap = true; speed = null; return false;
        }
        if (fixUtc != null && utc <= fixUtc) { return false; }
        var dt = fixUtc == null ? 1 : Geo.max(1, utc - fixUtc);
        gap = gap || (fixUtc != null && (dt > 5 || !wasUsable));
        lat = newLat; lon = newLon; fixUtc = utc;
        receivedMs = nowMs; initialAge = Geo.max(0, nowUtc - utc);
        speed = Geo.finite(newSpeed) && newSpeed >= 0 && newSpeed <= 50 ? newSpeed : null;
        if (!Geo.valid(lat, lon)) { xy = null; gap = true; return true; }
        xy = filter.update(Geo.project(lat, lon), lat, speed, q, dt, gap, motionHint);
        gap = gap || filter.rebased;
        var previous = (count > 0 ? trace[(head - 1 + CAPACITY) % CAPACITY] : null) as Array or Null;
        var moved = previous == null ? 0 : Geo.distance(xy, previous, lat);
        // No timer-only points while stationary; the bounded trace exists only in RAM.
        if (previous == null || gap || moved >= 3 || (moved >= 1 && utc - previous[2] >= 5)) {
            if (previous != null && !gap) { distance += moved; }
            trace[head] = [xy[0], xy[1], utc, gap];
            head = (head + 1) % CAPACITY; count = Geo.min(CAPACITY, count + 1); gap = false;
        }
        return true;
    }
    function point(index) as Array { return trace[(head - count + index + CAPACITY) % CAPACITY]; }
}
