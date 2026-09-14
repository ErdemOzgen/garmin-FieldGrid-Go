import Toybox.Test;
import Toybox.Application;
import Toybox.Math;
import Toybox.Position;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Time;

(:test)
function decimalCoordinateWirePrecision(logger) {
    Test.assert("52.00002000".equals(Geo.coordinateText(52.00002d)));
    Test.assert("5.00003000".equals(Geo.coordinateText(5.00003d)));
    Test.assert("-179.99999999".equals(Geo.coordinateText(-179.99999999d)));
    return true;
}

(:test)
function smallStorageProbeRoundTrip(logger) {
    var s = new FieldSession();
    s.probeStorage();
    Test.assert("1K OK".equals(s.storageStatus));
    Test.assert(Application.Storage.getValue("g0-probe") == null);
    return true;
}

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
    for (var i = 0; i < view.menuItems.size(); i++) { view.selection = i; view.onUpdate(dc); }
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
        [textResource(Rez.Strings.Usable) + " / 9999s", 42],
        [textResource(Rez.Strings.ServiceIssue), 326],
        [textResource(Rez.Strings.SettingsIssue), 326],
        [textResource(Rez.Strings.Offline), 326],
        [textResource(Rez.Strings.MapPending), 326],
        [textResource(Rez.Strings.Loading), 326],
        [textResource(Rez.Strings.Back), 338],
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
    var view = new FieldView(new FieldSession());
    for (var n = 0; n < view.menuItems.size(); n++) {
        var label = textResource(view.menuItems[n]);
        Test.assert(dc.getTextWidthInPixels(label, view.menuFont(dc, label)) <= 264);
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
    Test.assert(state.imageCount == 1);
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

(:test)
function coordinatesWithoutInternetAndAtPoles(logger) {
    var s = new FieldSession(); var v = new FieldView(s); var d = new FieldDelegate(v, s);
    // Home DOWN is an explicit GPS-only action, and must never start a network job.
    d.onNextPage();
    Test.assert(s.running && s.subscribed && !s.networkEnabled && v.page == :coordinates);
    var now = Time.now().value();
    Test.assert(s.gps.accept(-33.123456d, -179.999999d, now, Position.QUALITY_GOOD, null, now, System.getTimer()));
    s.map.track(s.gps.xy[0], s.gps.xy[1]); s.maybeRequest();
    Test.assert(s.job == null && s.map.requestCount == 0);
    Test.assert("-33.123456".equals(Geo.displayCoordinate(s.gps.lat)));
    Test.assert("-179.999999".equals(Geo.displayCoordinate(s.gps.lon)));
    Test.assert("--".equals(Geo.displayCoordinate(null)));
    var gps = new GpsState();
    Test.assert(gps.accept(90.0d, 180.0d, now, Position.QUALITY_GOOD, null, now, 0));
    Test.assert(gps.lat == 90 && gps.xy == null && gps.usable(1000));
    Test.assert(!gps.usable(6000));
    Test.assert("90.000000".equals(Geo.displayCoordinate(gps.lat)));
    s.stop();
    Test.assert(!s.running && !s.subscribed && s.job == null && s.map.bitmap == null);
    Test.assert(s.gps.lat == null && s.gps.count == 0);
    return true;
}

(:test)
function coordinatesAndCreditsFitRoundScreen(logger) {
    var canvas = Graphics.createBufferedBitmap({:width => 390, :height => 390});
    var dc = canvas.get().getDc();
    var labels = [["-90.000000",156,Graphics.FONT_SMALL], ["-180.000000",245,Graphics.FONT_SMALL],
        ["Age 9999s / WGS84",301,Graphics.FONT_XTINY], ["DOWN: GPS",335,Graphics.FONT_XTINY],
        ["Current fix",82,Graphics.FONT_XTINY], ["Last known fix",82,Graphics.FONT_XTINY],
        ["© OpenMapTiles",99,Graphics.FONT_XTINY], ["© OpenStreetMap",129,Graphics.FONT_XTINY],
        ["openstreetmap.org",285,Graphics.FONT_XTINY], ["GPS only",326,Graphics.FONT_XTINY],
        ["Low memory",326,Graphics.FONT_XTINY]];
    for (var i=0; i<labels.size(); i++) {
        var item=labels[i]; var height=dc.getFontHeight(item[2]);
        var edge=Geo.max(Geo.abs(item[1]-195),Geo.abs(item[1]+height-195));
        var allowed=2*Math.sqrt(195*195-edge*edge)-12;
        logger.debug("Coordinate/credit width " + dc.getTextWidthInPixels(item[0],item[2]) + " / " + allowed);
        Test.assert(dc.getTextWidthInPixels(item[0],item[2]) <= allowed);
    }
    var s = new FieldSession(); var v = new FieldView(s);
    v.page=:coordinates; v.onUpdate(dc);
    s.gps.lat=-90.0d; s.gps.lon=-180.0d; s.gps.receivedMs=System.getTimer();
    v.onUpdate(dc); v.page=:credits; v.onUpdate(dc);
    return true;
}

(:test)
function repeatedSessionsAndTwoHourGpsStream(logger) {
    var s = new FieldSession(); s.networkEnabled=false;
    var baseline=0; var peak=0; var bitmapPeak=0;
    for (var cycle=0; cycle<40; cycle++) {
        s.start();
        var now=Time.now().value();
        // First cycle exercises 2 hours of one-second events; subsequent cycles churn sessions.
        var length=cycle==0 ? 7200 : 200;
        for (var i=0; i<length; i++) {
            var utc=now+i;
            s.gps.accept(52.0d+(i%200)*0.0001d,5.0d,utc,Position.QUALITY_GOOD,null,utc,i*1000);
        }
        Test.assert(s.gps.count==180 && s.gps.trace.size()==180);
        // Native bitmap allocation/replacement with an explicitly bounded palette.
        for (var j=0; j<4; j++) {
            var size=cycle%3==0 ? 195 : (cycle%3==1 ? 256 : 390);
            var pal=new MapJob(s,0,0).palette();
            var bmp=Graphics.createBufferedBitmap({:width=>size,:height=>size,:palette=>pal});
            // Measure while BOTH old and incoming native bitmap references are alive.
            var live=System.getSystemStats();
            if (live.usedMemory>bitmapPeak) { bitmapPeak=live.usedMemory; }
            Test.assert(live.usedMemory < live.totalMemory*0.8);
            s.map.bitmap=bmp;
            bmp=null;
        }
        s.stop();
        Test.assert(s.gps.count==0 && s.gps.lat==null && s.map.bitmap==null && s.map.metadata==null);
        Test.assert(!s.subscribed && !s.running && s.job==null && !s.map.busy);
        var used=System.getSystemStats().usedMemory;
        if (cycle==5) { baseline=used; }
        if (used>peak) { peak=used; }
        if (cycle>5) { Test.assert(used <= baseline+16384); }
    }
    logger.debug("40 sessions / 15000 GPS events / 160 bitmap replacements; baseline="+baseline+", peak="+peak+", end="+System.getSystemStats().usedMemory+", bitmap overlap peak="+bitmapPeak);
    Test.assert(Application.Storage.getValue("g0-probe")==null);
    return true;
}

(:test)
function realProviderMetadataIsAuthenticatedAndAtomic(logger) {
    var state = new MapState(); state.camera(0,0);
    var data={"mapDataVersion"=>"openfreemap-test-v1","attribution"=>"OpenFreeMap | (c) OpenMapTiles | Data from OpenStreetMap"};
    Test.assert(state.validProvider(data));
    data["attribution"]="Wrong source"; Test.assert(!state.validProvider(data));
    data["mapDataVersion"]="other-provider"; Test.assert(!state.validProvider(data));
    return true;
}
