import Toybox.Lang;
import Toybox.Math;

module Geo {
    const R = 6378137.0d;
    const PI = 3.141592653589793d;
    const WORLD = 40075016.68557849d;
    const MAX_LAT = 85.0511287798066d;

    function abs(a) { return a < 0 ? -a : a; }

    function min(a, b) { return a < b ? a : b; }
    function max(a, b) { return a > b ? a : b; }

    // Decimal formatting preserves WGS84 precision.
    function coordinateText(degrees) { return degrees.format("%.8f"); }

    function displayCoordinate(degrees) { return degrees == null ? "--" : degrees.format("%.6f"); }

    function validGps(lat, lon) {
        return finite(lat) && finite(lon) && lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
    }

    function finite(v) {
        return (v instanceof Number || v instanceof Float || v instanceof Double || v instanceof Long)
            && v == v && v < 1.0e100d && v > -1.0e100d;
    }

    function valid(lat, lon) {
        return finite(lat) && finite(lon) && lat >= -MAX_LAT && lat <= MAX_LAT
            && lon >= -180 && lon <= 180;
    }

    function project(lat, lon) as Array {
        return [R * lon.toDouble() * PI / 180.0d,
            R * Math.ln(Math.tan(PI / 4.0d + lat.toDouble() * PI / 360.0d))];
    }

    function inverse(x, y) as Array {
        var lon = x / R * 180.0d / PI;
        while (lon > 180) { lon -= 360; }
        while (lon < -180) { lon += 360; }
        return [(2 * Math.atan(Math.pow(2.718281828459045d, y / R)) - PI / 2.0d) * 180.0d / PI, lon];
    }

    function resolution(zoom) { return WORLD / (256.0d * Math.pow(2, zoom)); }

    function bounds(x, y, zoom) as Array {
        var half = 195.0d * resolution(zoom);
        return [x - half, y - half, x + half, y + half];
    }

    function pixel(x, y, box as Array, size) as Array {
        var center = (box[0] + box[2]) / 2;
        x += Math.round((center - x) / WORLD) * WORLD;
        return [(x - box[0]) * size / (box[2] - box[0]),
            (box[3] - y) * size / (box[3] - box[1])];
    }

    function wrapX(x) { return x - Math.floor((x + WORLD / 2) / WORLD) * WORLD; }
    function distance(a as Array, b as Array, latitude) {
        var dx = wrapX(a[0] - b[0]); var dy = a[1] - b[1];
        return Math.sqrt(dx * dx + dy * dy) * Math.cos(latitude * PI / 180.0d);
    }
    function gridStep(span) {
        var power = 0.000001d;
        while (power * 10 < span) { power *= 10; }
        if (span <= power) { return power; }
        if (span <= 2 * power) { return 2 * power; }
        if (span <= 5 * power) { return 5 * power; }
        return 10 * power;
    }
    function distanceText(meters) {
        if (meters == null) { return "--"; }
        return meters >= 1000 ? (meters / 1000.0).format("%.2f") + " km" : meters.format("%.0f") + " m";
    }
    function timeText(seconds) {
        var s = max(0, seconds).toNumber();
        var hours = s / 3600; var minutes = (s / 60) % 60;
        return hours > 0 ? hours + ":" + minutes.format("%02d") + ":" + (s % 60).format("%02d") :
            minutes.format("%02d") + ":" + (s % 60).format("%02d");
    }
}
