import Toybox.Position;
import Toybox.Math;
import Toybox.Lang;

// Pure state is shared by the live adapter and Monkey C unit tests.
class GpsState {
    var lat = null;
    var lon = null;
    var xy as Array or Null = null;
    var quality = Position.QUALITY_NOT_AVAILABLE;
    var fixUtc = null;
    var receivedMs = null;
    var initialAge = 0;
    var heading = null;
    var trace as Array;
    var count = 0;
    var head = 0;
    var gap = true;
    const CAPACITY = 180;

    function initialize() { trace = new [CAPACITY]; }

    function age(nowMs) {
        if (receivedMs == null) { return null; }
        var elapsed = (nowMs - receivedMs) / 1000.0;
        // Monotonic wrap is treated as stale, never fresh.
        if (elapsed < 0) { return 9999; }
        return initialAge + elapsed;
    }

    function usable(nowMs) {
        var a = age(nowMs);
        return a != null && a <= 5 &&
            (quality == Position.QUALITY_GOOD || quality == Position.QUALITY_USABLE);
    }

    function accept(newLat, newLon, utc, q, direction, nowUtc, nowMs) {
        quality = q;
        if (!Geo.validGps(newLat, newLon) || !Geo.finite(utc) || utc <= 0 ||
            utc > nowUtc + 2 || (q != Position.QUALITY_GOOD && q != Position.QUALITY_USABLE)) {
            gap = true;
            return false;
        }
        if (fixUtc != null && utc <= fixUtc) { return false; }
        if (nowUtc - utc > 5) { gap = true; return false; }
        if (fixUtc != null && (utc - fixUtc > 5 || !usable(nowMs))) { gap = true; }
        lat = newLat; lon = newLon; fixUtc = utc;
        receivedMs = nowMs; initialAge = nowUtc > utc ? nowUtc - utc : 0;
        xy = Geo.valid(lat, lon) ? Geo.project(lat, lon) : null;
        heading = Geo.finite(direction) && direction >= 0 && direction < 2 * Geo.PI ? direction : null;
        if (xy == null) { gap = true; return true; }
        var previous = (count > 0 ? trace[(head - 1 + CAPACITY) % CAPACITY] : null) as Array or Null;
        var add = previous == null || gap || utc - previous[2] >= 5;
        if (!add) {
            var dx = xy[0] - previous[0];
            dx -= Math.round(dx / Geo.WORLD) * Geo.WORLD;
            var dy = xy[1] - previous[1];
            var cosLat = Math.cos(lat * Geo.PI / 180.0d);
            add = (dx * dx + dy * dy) * cosLat * cosLat >= 9;
        }
        if (add) {
            trace[head] = [xy[0], xy[1], utc, gap];
            head = (head + 1) % CAPACITY;
            if (count < CAPACITY) { count++; }
            gap = false;
        }
        return true;
    }

    function point(index) as Array { return trace[(head - count + index + CAPACITY) % CAPACITY]; }
}
