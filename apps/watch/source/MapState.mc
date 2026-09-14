import Toybox.Lang;
import Toybox.Math;

// At most one job, a coalesced desired camera, and one active raster.
class MapState {
    var generation = 0;
    var center as Array or Null = null;
    var zoom = 15;
    var style = "day";
    var size = 390;
    var follow = true;
    var metadata as Dictionary or Null = null;
    var bitmap = null;
    var busy = false;
    var wanted = false;
    var active = false;
    var lastStart = -5000;
    var nextAttempt = 0;
    var failures = 0;
    var lastCode = 0;
    var permanent = false;
    var requestCount = 0;
    var imageCount = 0;
    var lastDuration = 0;
    var validationIssue = "none";

    function initialize() {}

    function camera(x, y) {
        center = [x, y]; generation++; wanted = true;
    }

    function track(x, y) {
        if (!follow) { return; }
        if (center == null) { camera(x, y); return; }
        var p = Geo.pixel(x, y, Geo.bounds(center[0], center[1], zoom), 390);
        var dx = p[0] - 195; var dy = p[1] - 195;
        if (dx * dx + dy * dy > 48.75 * 48.75) { camera(x, y); }
    }

    function changeZoom(delta) {
        var z = zoom + delta;
        if (z < 14 || z > 16) { return; }
        zoom = z; generation++; wanted = true;
    }

    function canStart(now) {
        return active && !busy && !permanent && wanted && center != null &&
            now - lastStart >= 5000 && now >= nextAttempt;
    }

    function start(now) { busy = true; wanted = false; lastStart = now; requestCount++; }

    function fail(code, now, retryAfter) {
        busy = false; lastCode = code; wanted = true;
        permanent = code == 401 || code == 403 || code == 413 || code == 422 || code == -900;
        failures++;
        var delay = Geo.min(30, Math.pow(2, Geo.min(failures, 5)));
        if (code == 429 && retryAfter != null) { delay = Geo.max(delay, retryAfter); }
        nextAttempt = now + delay * 1000 + Math.rand() % 501;
    }

    function validate(data, expectedGeneration, baseUrl) {
        validationIssue = "schema";
        if (!(data instanceof Dictionary)) { return false; }
        if (data["schemaVersion"] != 1 || data["requestGeneration"] != expectedGeneration ||
            !"EPSG:3857".equals(data["projection"]) || data["imageWidth"] != size ||
            data["imageHeight"] != size || data["zoom"] != zoom ||
            !(style + "-v1").equals(data["styleVersion"]) ||
            !"synthetic-grid-v1".equals(data["mapDataVersion"]) ||
            !"SYNTHETIC TEST MAP".equals(data["attribution"])) { return false; }
        var id = data["renderId"]; var url = data["imageUrl"]; var box = data["bounds3857"];
        validationIssue = "grant";
        if (!(id instanceof String) || id.length() != 32 || !(url instanceof String) ||
            url.find(baseUrl + "/v1/images/" + id + "?") != 0 ||
            !(box instanceof Array) || box.size() != 4 || !Geo.finite(data["expiresAt"])) { return false; }
        var expected = Geo.bounds(center[0], center[1], zoom);
        validationIssue = "bounds";
        for (var i = 0; i < 4; i++) {
            if (!Geo.finite(box[i]) || Geo.abs(box[i] - expected[i]) > 2) {
                if (Geo.finite(box[i])) { System.println("G0 bounds residual meters: " + (box[i] - expected[i])); }
                return false;
            }
        }
        if (box[2] <= box[0] || box[3] <= box[1]) { return false; }
        validationIssue = "none";
        return true;
    }

    function commit(data, image, gen, now) {
        busy = false;
        if (!active || gen != generation) { wanted = active; return false; }
        // Swap only when both validated resources are available.
        bitmap = image; metadata = data; failures = 0; lastCode = 0;
        imageCount++;
        lastDuration = now - lastStart;
        return true;
    }
}
