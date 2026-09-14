import Toybox.Application;
import Toybox.Communications;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.PersistedContent;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

class FieldMapApp extends Application.AppBase {
    var session as FieldSession;
    function initialize() { AppBase.initialize(); session = new FieldSession(); }
    function getInitialView() {
        var view = new FieldView(session);
        return [view, new FieldDelegate(view, session)];
    }
    function onStart(state) {}
    function onStop(state) { session.stop(); }
    function onInactive(state) { session.pause(); }
    function onActive(state) { session.resume(); }
}

class FieldSession {
    var gps as GpsState;
    var map as MapState;
    var running = false;
    var subscribed = false;
    var ticker;
    var epoch = 0;
    var job = null;
    var baseUrl = "";
    var token = "";
    var configError = false;
    var storageStatus = "NOT RUN";
    var peakMemory = 0;
    var updateCount = 0;

    function initialize() {
        gps = new GpsState(); map = new MapState(); ticker = new Timer.Timer();
        try {
            var saved = Application.Storage.getValue("preferences-v1");
            if (saved instanceof Dictionary) {
                if (saved["zoom"] == 14 || saved["zoom"] == 15 || saved["zoom"] == 16) { map.zoom = saved["zoom"]; }
                if ("day".equals(saved["style"]) || "night".equals(saved["style"])) { map.style = saved["style"]; }
            }
            baseUrl = Application.Properties.getValue("baseUrl");
            token = Application.Properties.getValue("devToken");
            var allowLocal = Application.Properties.getValue("allowLocalHttp");
            if (!(baseUrl instanceof String) || !(token instanceof String)) {
                baseUrl = ""; token = ""; configError = true;
            }
            if (baseUrl.length() != 0 && baseUrl.find("https://") != 0 &&
                !(allowLocal == true && "http://127.0.0.1:8765".equals(baseUrl))) {
                baseUrl = ""; configError = true;
            }
        } catch (e) { configError = true; }
    }

    function save() {
        try {
            Application.Storage.setValue("preferences-v1", {"zoom" => map.zoom, "style" => map.style});
        } catch (e) { storageStatus = "WRITE FAILED"; }
    }

    function start() {
        if (running) { return; }
        running = true; gps = new GpsState(); map.metadata = null; map.bitmap = null;
        map.center = null; map.follow = true; map.generation++; map.failures = 0;
        map.nextAttempt = 0; map.permanent = false; map.lastCode = 0;
        resume();
    }

    function resume() {
        if (!running || subscribed) { return; }
        gps.quality = Position.QUALITY_NOT_AVAILABLE; gps.gap = true;
        map.active = true;
        if (map.center != null) { map.wanted = true; }
        subscribed = true;
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
        ticker.start(method(:tick), 1000, true);
    }

    function pause() {
        if (subscribed) {
            subscribed = false;
            Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        }
        ticker.stop(); epoch++; job = null;
        map.active = false; map.busy = false; gps.gap = true;
        Communications.cancelAllRequests();
    }

    function stop() {
        running = false; pause(); save();
        gps = new GpsState(); map.bitmap = null; map.metadata = null; map.center = null;
    }

    function onPosition(info as Position.Info) as Void {
        if (!running || !subscribed) { return; }
        if (info.position == null || info.when == null) {
            gps.quality = Position.QUALITY_NOT_AVAILABLE; gps.gap = true;
        } else {
            var degrees = info.position.toDegrees();
            if (gps.accept(degrees[0], degrees[1], info.when.value(), info.accuracy,
                info.heading, Time.now().value(), System.getTimer())) {
                map.track(gps.xy[0], gps.xy[1]);
                maybeRequest();
            }
        }
        // Marker refresh never waits for a raster response.
        updateCount++; WatchUi.requestUpdate();
    }

    function tick() {
        if (!subscribed) { return; }
        var now = System.getTimer();
        if (map.busy && now - map.lastStart >= 25000) {
            epoch++; job = null; Communications.cancelAllRequests();
            map.fail(-901, now, null);
        }
        maybeRequest();
        var memory = System.getSystemStats().usedMemory;
        if (memory > peakMemory) { peakMemory = memory; }
        WatchUi.requestUpdate();
    }

    function maybeRequest() {
        if (baseUrl.length() == 0 || !map.canStart(System.getTimer())) { return; }
        map.start(System.getTimer()); epoch++;
        job = new MapJob(self, epoch, map.generation);
        job.start();
    }

    function current(id) { return subscribed && map.active && id == epoch; }

    function pan(dx, dy) {
        if (map.center == null) { return; }
        map.follow = false;
        var step = Geo.resolution(map.zoom) * 70;
        var x = map.center[0] + dx * step;
        var y = map.center[1] + dy * step;
        y = Geo.max(-Geo.WORLD / 2, Geo.min(Geo.WORLD / 2, y));
        if (x > Geo.WORLD / 2) { x -= Geo.WORLD; }
        if (x < -Geo.WORLD / 2) { x += Geo.WORLD; }
        map.camera(x, y);
    }

    function recenter() {
        map.follow = true;
        if (gps.xy != null) { map.camera(gps.xy[0], gps.xy[1]); }
    }

    function probeStorage() {
        var result = "";
        var s = "0123456789abcdef";
        while (s.length() < 32768) { s += s; }
        var sizes = [1024, 32000, 32768];
        for (var i = 0; i < sizes.size(); i++) {
            try {
                Application.Storage.setValue("g0-probe", s.substring(0, sizes[i]));
                var read = Application.Storage.getValue("g0-probe");
                result += read instanceof String && read.length() == sizes[i] ? "OK " : "BAD ";
            } catch (e) { result += "LIMIT "; }
            try { Application.Storage.deleteValue("g0-probe"); } catch (e) {}
        }
        storageStatus = result;
    }
}

class MapJob {
    var owner as FieldSession; var id; var gen; var pending as Dictionary or Null = null;
    function initialize(session, number, generation) { owner = session; id = number; gen = generation; }
    function start() {
        var m = owner.map;
        var ll = Geo.inverse(m.center[0], m.center[1]);
        var headers = {"Content-Type" => Communications.REQUEST_CONTENT_TYPE_JSON};
        if (owner.token.length() != 0) { headers["Authorization"] = "Bearer " + owner.token; }
        try {
            Communications.makeWebRequest(owner.baseUrl + "/v1/map-renders",
                {"schemaVersion" => 1, "requestGeneration" => gen, "latDeg" => ll[0],
                 "lonDeg" => ll[1], "zoom" => m.zoom, "style" => m.style, "imageSize" => m.size},
                {:method => Communications.HTTP_REQUEST_METHOD_POST, :headers => headers,
                 :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON}, method(:onMetadata));
        } catch (e) { fail(-902, null); }
    }

    function obsolete() {
        if (!owner.current(id)) { return true; }
        if (owner.map.generation != gen) {
            owner.map.busy = false; owner.map.wanted = true; owner.job = null;
            return true;
        }
        return false;
    }

    function fail(code, data) {
        if (obsolete()) { return; }
        var retry = null;
        if (data instanceof Dictionary && Geo.finite(data["retryAfterSec"])) {
            retry = Geo.max(0, Geo.min(3600, data["retryAfterSec"]));
        }
        owner.map.fail(code, System.getTimer(), retry); owner.job = null;
        WatchUi.requestUpdate();
    }

    function onMetadata(code as Number, data as Dictionary or String or PersistedContent.Iterator or Null) as Void {
        if (obsolete()) { return; }
        if (code != 200) { fail(code, data); return; }
        if (!(data instanceof Dictionary)) { fail(-900, null); return; }
        if (!owner.map.validate(data, gen, owner.baseUrl) || data["expiresAt"] <= Time.now().value()) {
            fail(-900, null); return;
        }
        pending = data;
        try {
            Communications.makeImageRequest(data["imageUrl"], null,
                {:maxWidth => owner.map.size, :maxHeight => owner.map.size,
                 :dithering => Communications.IMAGE_DITHERING_NONE}, method(:onImage));
        } catch (e) { fail(-902, null); }
    }

    function onImage(code as Number, data as Graphics.BitmapReference or WatchUi.BitmapResource or Null) as Void {
        if (obsolete()) { return; }
        if (code != 200 || data == null) { fail(code == 200 ? -903 : code, null); return; }
        var bitmap = data instanceof Graphics.BitmapReference ? data.get() : data;
        if (bitmap.getWidth() != pending["imageWidth"] || bitmap.getHeight() != pending["imageHeight"]) {
            fail(-900, null); return;
        }
        owner.map.commit(pending, data, gen, System.getTimer());
        owner.job = null; WatchUi.requestUpdate();
    }
}
