import Toybox.Test;
import Toybox.Math;
import Toybox.Position;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Time;

(:test)
function projectionControlPoints(logger) {
    var p = Geo.project(45.0d, 90.0d);
    Test.assert(Geo.abs(p[0] - 10018754.171394622d) < 0.1);
    Test.assert(Geo.abs(p[1] - 5621521.486192066d) < 0.1);
    var zero = Geo.project(0.0d, 0.0d);
    Test.assert(Geo.abs(zero[0]) < 0.01 && Geo.abs(zero[1]) < 0.01);
    return true;
}

(:test)
function projectionHemispheres(logger) {
    var inputs = [[52.0d, 5.0d], [50.85d, 4.35d], [-33.0d, 18.0d], [0.0d, -1.0d]];
    for (var i = 0; i < inputs.size(); i++) {
        var p = Geo.project(inputs[i][0], inputs[i][1]);
        var ll = Geo.inverse(p[0], p[1]);
        Test.assert(Geo.abs(ll[0] - inputs[i][0]) < 0.000001d);
        Test.assert(Geo.abs(ll[1] - inputs[i][1]) < 0.000001d);
        var pixel = Geo.pixel(p[0], p[1], Geo.bounds(p[0], p[1], 15), 390);
        Test.assert(Geo.abs(pixel[0] - 195) < 0.01 && Geo.abs(pixel[1] - 195) < 0.01);
    }
    return true;
}

(:test)
function antimeridianAndBadCoordinates(logger) {
    var c = Geo.project(0, 179.999d); var p = Geo.project(0, -179.999d);
    var xy = Geo.pixel(p[0], p[1], Geo.bounds(c[0], c[1], 14), 390);
    Test.assert(xy[0] > 195 && xy[0] < 250);
    Test.assert(!Geo.valid(null, 0)); Test.assert(!Geo.valid(86, 0));
    Test.assert(!Geo.valid(0, 181)); Test.assert(!Geo.valid("52", 5));
    return true;
}

(:test)
function gpsAgesAndInvalidSamples(logger) {
    var gps = new GpsState();
    Test.assert(!gps.accept(null, 5, 100, Position.QUALITY_GOOD, null, 100, 0));
    Test.assert(gps.xy == null);
    Test.assert(!gps.accept(52, 5, null, Position.QUALITY_GOOD, null, 100, 0));
    Test.assert(!gps.accept(52, 5, 110, Position.QUALITY_GOOD, null, 100, 0));
    Test.assert(!gps.accept(52, 5, 90, Position.QUALITY_GOOD, null, 100, 0));
    Test.assert(gps.accept(52, 5, 100, Position.QUALITY_GOOD, null, 100, 0));
    Test.assert(gps.usable(5000)); Test.assert(!gps.usable(5001));
    Test.assert(!gps.accept(0, 0, 99, Position.QUALITY_GOOD, null, 101, 1000));
    Test.assert(gps.lat == 52);
    Test.assert(!gps.accept(52, 5, 102, Position.QUALITY_LAST_KNOWN, null, 102, 2000));
    Test.assert(!gps.usable(2000));
    return true;
}

(:test)
function boundedTraceAndGaps(logger) {
    var gps = new GpsState();
    for (var i = 0; i < 1000; i++) {
        Test.assert(gps.accept(52.0d + i * 0.0001d, 5, 100 + i, Position.QUALITY_GOOD, null, 100 + i, i * 1000));
    }
    Test.assert(gps.count == 180);
    Test.assert(gps.accept(52.2d, 5, 1110, Position.QUALITY_GOOD, null, 1110, 1010000));
    Test.assert(gps.point(179)[3]);
    return true;
}

(:test)
function traceSimplifiesStationaryFixes(logger) {
    var gps = new GpsState();
    for (var i = 0; i < 20; i++) {
        gps.accept(52, 5, 100 + i, Position.QUALITY_GOOD, null, 100 + i, i * 1000);
    }
    Test.assert(gps.count == 4);
    return true;
}

(:test)
function requestCoalescingAndBackoff(logger) {
    var state = new MapState(); state.active = true; state.camera(0, 0);
    Test.assert(state.canStart(0)); state.start(0);
    state.changeZoom(1); state.changeZoom(-1); state.changeZoom(-1);
    Test.assert(!state.canStart(6000));
    state.fail(503, 1000, null);
    Test.assert(!state.canStart(4999)); Test.assert(state.canStart(6000));
    state.start(6000); state.fail(429, 6500, 60);
    Test.assert(!state.canStart(66000)); Test.assert(state.canStart(68000));
    state.start(68000); state.fail(401, 69000, null);
    Test.assert(!state.canStart(1000000));
    state.camera(100, 100);
    Test.assert(!state.canStart(1000000));
    return true;
}

(:test)
function oldCallbackCannotReleaseNewJob(logger) {
    var s = new FieldSession(); s.subscribed = true; s.map.active = true;
    s.map.busy = true; s.epoch = 10;
    var job = new MapJob(s, 9, s.map.generation);
    job.onMetadata(503, null); job.onImage(200, null);
    Test.assert(s.map.busy && s.map.lastCode == 0);
    s.subscribed = false;
    return true;
}

(:test)
function renderEveryScreenAndRaster(logger) {
    var canvas = Graphics.createBufferedBitmap({:width => 390, :height => 390});
    var dc = canvas.get().getDc();
    var s = new FieldSession();
    Test.assert(!s.running && !s.subscribed);
    var view = new FieldView(s);
    Test.assert(view.page == :home);
    view.onUpdate(dc);
    view.page = :map; view.onUpdate(dc);
    var now = Time.now().value();
    s.gps.accept(52.0d, 5.0d, now, Position.QUALITY_GOOD, 1.0, now, System.getTimer());
    s.map.track(s.gps.xy[0], s.gps.xy[1]);
    view.onUpdate(dc);
    s.baseUrl = ""; view.onUpdate(dc);
    s.map.style = "night"; view.onUpdate(dc);
    var raster = Graphics.createBufferedBitmap({:width => 195, :height => 195});
    s.map.bitmap = raster;
    s.map.metadata = {"bounds3857" => Geo.bounds(s.map.center[0], s.map.center[1], 15)};
    view.onUpdate(dc);
    view.page = :pan; view.onUpdate(dc);
    view.page = :menu;
    for (var i = 0; i < 8; i++) { view.selection = i; view.onUpdate(dc); }
    view.page = :diagnostics; view.onUpdate(dc);
    logger.debug("390px canvas rendered. FONT_SMALL=" + dc.getFontHeight(Graphics.FONT_SMALL) +
        "px; FONT_XTINY=" + dc.getFontHeight(Graphics.FONT_XTINY) + "px");
    return true;
}

(:test)
function criticalLabelsFitRoundScreen(logger) {
    var canvas = Graphics.createBufferedBitmap({:width => 390, :height => 390});
    var dc = canvas.get().getDc();
    var labels = [
        [textResource(Rez.Strings.Waiting), 42],
        [textResource(Rez.Strings.Good) + " / 0s", 42],
        [textResource(Rez.Strings.Stale) + " / 9999s", 42],
        [textResource(Rez.Strings.ServiceIssue), 326],
        [textResource(Rez.Strings.SettingsIssue), 326],
        [textResource(Rez.Strings.Synthetic), 105],
        [textResource(Rez.Strings.Consent1), 141],
        [textResource(Rez.Strings.Consent2), 173],
        [textResource(Rez.Strings.Consent3), 205],
        [textResource(Rez.Strings.Consent4), 237]
    ];
    for (var i = 0; i < labels.size(); i++) {
        var label = labels[i];
        var height = dc.getFontHeight(Graphics.FONT_XTINY);
        var edge = Geo.max(Geo.abs(label[1] - 195), Geo.abs(label[1] + height - 195));
        var allowed = 2 * Math.sqrt(195 * 195 - edge * edge) - 12;
        var width = dc.getTextWidthInPixels(label[0], Graphics.FONT_XTINY);
        logger.debug("Label width " + width + " / safe " + allowed.format("%.0f"));
        Test.assert(width <= allowed);
    }
    return true;
}

(:test)
function malformedMetadataPreservesActiveMap(logger) {
    var s = new FieldSession(); s.subscribed = true; s.map.active = true; s.epoch = 2;
    s.map.camera(0, 0); s.map.busy = true;
    s.map.metadata = {"renderId" => "previous"};
    var job = new MapJob(s, 2, s.map.generation);
    job.onMetadata(200, {"schemaVersion" => 2});
    Test.assert(!s.map.busy && s.map.permanent && s.map.lastCode == -900);
    Test.assert("previous".equals(s.map.metadata["renderId"]));
    s.subscribed = false;
    return true;
}

(:test)
function menuAndFollowControls(logger) {
    var s = new FieldSession(); var view = new FieldView(s); var delegate = new FieldDelegate(view, s);
    Test.assert(!s.subscribed); Test.assert(!delegate.onBack());
    view.page = :map; s.map.camera(0, 0);
    delegate.onSelect(); Test.assert(view.page == :menu);
    view.selection = 1; delegate.onSelect(); Test.assert(view.page == :pan);
    delegate.onPreviousPage(); Test.assert(!s.map.follow);
    var y = s.map.center[1]; delegate.onSelect(); delegate.onPreviousPage();
    Test.assert(s.map.center[0] != 0 && s.map.center[1] == y);
    delegate.onBack(); Test.assert(view.page == :map && s.map.follow);
    return true;
}

(:test)
function staleRasterCannotReplaceNewCamera(logger) {
    var state = new MapState(); state.active = true; state.camera(0, 0);
    var old = state.generation; state.changeZoom(1);
    Test.assert(!state.commit({"renderId" => "old"}, null, old, 100));
    Test.assert(state.metadata == null && state.zoom == 16);
    Test.assert(state.commit({"renderId" => "new"}, null, state.generation, 200));
    state.active = false;
    Test.assert(!state.commit({"renderId" => "late"}, null, state.generation, 300));
    Test.assert("new".equals(state.metadata["renderId"]));
    return true;
}

(:test)
function browseKeepsCamera(logger) {
    var state = new MapState(); state.camera(0, 0); state.follow = false;
    state.track(1000, 1000); Test.assert(state.center[0] == 0);
    state.follow = true; state.track(1000, 1000);
    Test.assert(state.center[0] == 1000);
    return true;
}

(:test)
function metadataValidation(logger) {
    var state = new MapState(); state.camera(0, 0);
    var id = "0123456789abcdef0123456789abcdef";
    var data = {"schemaVersion" => 1, "requestGeneration" => state.generation,
        "projection" => "EPSG:3857", "imageWidth" => 390, "imageHeight" => 390,
        "zoom" => 15, "styleVersion" => "day-v1", "mapDataVersion" => "synthetic-grid-v1",
        "attribution" => "SYNTHETIC TEST MAP", "renderId" => id,
        "imageUrl" => "https://example.com/v1/images/" + id + "?sig=test",
        "expiresAt" => 200, "bounds3857" => Geo.bounds(0, 0, 15)};
    Test.assert(state.validate(data, state.generation, "https://example.com"));
    data["imageWidth"] = 256;
    Test.assert(!state.validate(data, state.generation, "https://example.com"));
    data["imageWidth"] = 390; data["bounds3857"] = [0, 0, 1, 1];
    Test.assert(!state.validate(data, state.generation, "https://example.com"));
    return true;
}
