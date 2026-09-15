import Toybox.Test;
import Toybox.Application;
import Toybox.Math;
import Toybox.Position;
import Toybox.Graphics;
import Toybox.System;
import Toybox.Lang;

(:test)
module Synthetic {
function fix(g, meters, t, speed) {
    return g.accept(52.0d + meters / 111319.49d, 5.0d, 100 + t, Position.QUALITY_GOOD, speed, 100 + t, t * 1000);
}
}

(:test)
function projectionAndDateLine(logger) {
    var inputs = [[52.0d, 5.0d], [-33.0d, 18.0d], [0.0d, 179.999d], [85.0d, -179.99d]];
    for (var i = 0; i < inputs.size(); i++) {
        var p = Geo.project(inputs[i][0], inputs[i][1]); var ll = Geo.inverse(p[0], p[1]);
        Test.assert(Geo.abs(ll[0] - inputs[i][0]) < 0.000001d);
        Test.assert(Geo.abs(ll[1] - inputs[i][1]) < 0.000001d);
        var pixel = Geo.pixel(p[0], p[1], Geo.bounds(p[0], p[1], 17), 390);
        Test.assert(Geo.abs(pixel[0] - 195) < 0.001);
    }
    Test.assert(Geo.distance(Geo.project(0, 179.999d), Geo.project(0, -179.999d), 0) < 223);
    Test.assert("-179.999999".equals(Geo.displayCoordinate(-179.999999d)));
    Test.assert(!Geo.validGps(null, 5) && !Geo.validGps(91, 0) && !Geo.validGps(0, 181));
    return true;
}

(:test)
function gpsFreshnessQualityAndPolar(logger) {
    var g = new GpsState();
    Test.assert(!g.accept(null, 5, 100, Position.QUALITY_GOOD, null, 100, 0));
    Test.assert(!g.accept(52, 5, 120, Position.QUALITY_GOOD, null, 100, 0));
    Test.assert(!g.accept(52, 5, 90, Position.QUALITY_GOOD, null, 100, 0));
    Test.assert(Synthetic.fix(g, 0, 0, null));
    Test.assert(g.usable(5000) && !g.usable(5001));
    Test.assert(!g.accept(0, 0, 99, Position.QUALITY_GOOD, null, 101, 1000));
    Test.assert(g.lat == 52);
    Test.assert(!g.accept(52, 5, 101, Position.QUALITY_POOR, null, 101, 1000));
    Test.assert(!g.usable(1000));
    Test.assert(g.accept(89, -170, 102, Position.QUALITY_GOOD, null, 102, 2000));
    Test.assert(g.lat == 89 && g.lon == -170 && g.xy == null);
    Test.assert(g.usable(2000));
    Test.assert(!g.usable(-1));
    return true;
}

(:test)
function stationaryNoiseDoesNotGrowTrace(logger) {
    var g = new GpsState(); Synthetic.fix(g, 0, 0, 0.0);
    for (var i = 1; i < 600; i++) { Synthetic.fix(g, (i % 7) - 3, i, 0.0); }
    Test.assert(g.count == 1 && g.distance == 0);
    Test.assert(Geo.distance(g.xy, Geo.project(52, 5), 52) < 0.01);
    Test.assert(!g.filter.moving);
    logger.debug("SYNTHETIC: 600 stationary fixes, +/-3 m: 1 point / 0 m trace");
    return true;
}

(:test)
function stationaryWideDriftCannotOverrideLowSpeed(logger) {
    var g = new GpsState(); Synthetic.fix(g, 0, 0, 0.0);
    for (var i = 1; i <= 600; i++) {
        // User reported stationary drift in the 12 to 34 meter range.
        // Synthetic ramp, plateau and reverse drift; these are not a real GPS log.
        var offset = i < 200 ? i * 0.17 : (i < 400 ? 34 : 34 - (i - 400) * 0.17);
        Synthetic.fix(g, offset, i, (i % 7) * 0.03);
    }
    Test.assert(g.count == 1 && g.distance == 0 && !g.filter.moving);
    Test.assert(Geo.distance(g.xy, Geo.project(52, 5), 52) < 0.01);
    logger.debug("SYNTHETIC 600 fixes / 34 m stationary drift: marker held, zero distance");
    return true;
}

(:test)
function stoppedWalkDoesNotConsumeStationaryDrift(logger) {
    var g = new GpsState();
    for (var i = 0; i < 60; i++) { Synthetic.fix(g, i * 1.4, i, 1.4); }
    for (var j = 60; j < 70; j++) { Synthetic.fix(g, 59 * 1.4, j, 0.0); }
    var distance = g.distance; var point = [g.xy[0], g.xy[1]]; var count = g.count;
    for (var k = 70; k < 670; k++) {
        var drift = ((k - 70) % 200) * 0.17;
        Synthetic.fix(g, 59 * 1.4 + drift, k, 0.05);
    }
    Test.assert(g.distance == distance && g.count == count);
    Test.assert(Geo.distance(g.xy, point, 52) < 0.01);
    return true;
}

(:test)
function stationaryDriftRejectsIsolatedSpeedSpikes(logger) {
    var g = new GpsState();
    for (var i = 0; i < 600; i++) {
        var offset = (i % 200) * 0.17;
        // A speed spike, missing speed and USABLE quality must not unlock drift.
        var speed = i % 17 == 0 ? null : (i % 9 == 0 ? 1.6 : 0.05);
        g.accept(52.0d + offset / 111319.49d, 5.0d, 100 + i,
            Position.QUALITY_USABLE, speed, 100 + i, i * 1000);
    }
    Test.assert(g.count == 1 && g.distance == 0 && !g.filter.moving);
    return true;
}

(:test)
function unknownSpeedSlowDriftDoesNotIntegrateForever(logger) {
    var g = new GpsState();
    for (var i = 0; i < 600; i++) { Synthetic.fix(g, Geo.min(i, 283) * 0.12, i, null); }
    Test.assert(g.count == 1 && g.distance == 0);
    return true;
}

(:test)
function walkingAfterDriftDoesNotCountHeldOffset(logger) {
    var g = new GpsState();
    for (var i = 0; i < 200; i++) { Synthetic.fix(g, i * 0.17, i, 0.05); }
    Test.assert(g.distance == 0);
    for (var j = 200; j < 260; j++) { Synthetic.fix(g, 34 + (j - 200) * 1.4, j, 1.4); }
    Test.assert(g.filter.moving && g.distance > 70 && g.distance < 85);
    Test.assert(g.point(1)[3]);
    Test.assert(Geo.distance(g.xy, Geo.project(52.0d + (34 + 59 * 1.4) / 111319.49d, 5), 52) < 4.3);
    logger.debug("SYNTHETIC resumed walking: 34 m held GPS offset excluded from distance");
    return true;
}

(:test)
function slowWalkingWithUsableQualityAndSparseFixes(logger) {
    var g = new GpsState();
    for (var i = 0; i <= 120; i += 2) {
        g.accept(52.0d + i * 0.35 / 111319.49d, 5.0d, 100 + i,
            Position.QUALITY_USABLE, 0.35, 100 + i, i * 1000);
    }
    Test.assert(g.filter.moving && g.distance > 35 && g.distance < 43);
    Test.assert(Geo.distance(g.xy, Geo.project(52.0d + 42 / 111319.49d, 5), 52) < 3);
    return true;
}

(:test)
function filteredCoordinatesAndRawToggleStayLocal(logger) {
    var s = new FieldSession(); var v = new FieldView(s); var d = new FieldDelegate(v, s);
    Test.assert(v.coordinateValues()[0] == null);
    d.onNextPage(); Test.assert(s.running && v.page == :coordinates && !v.rawCoordinates);
    for (var i = 0; i < 200; i++) { Synthetic.fix(s.gps, i * 0.17, i, 0.05); }
    Test.assert(Geo.abs(v.coordinateValues()[0] - 52.0d) < 0.000001d);
    var timer = s.ticker; var count = s.gps.count;
    d.onSelect(); Test.assert(v.rawCoordinates && v.coordinateValues()[0] == s.gps.lat);
    Test.assert(s.gps.lat > 52.0002d && s.ticker == timer && s.gps.count == count);
    d.onSelect(); Test.assert(!v.rawCoordinates && Geo.abs(v.coordinateValues()[0] - 52.0d) < 0.000001d);
    s.gps.accept(89, -170, 400, Position.QUALITY_GOOD, 0.0, 400, 300000);
    Test.assert(v.coordinateValues()[0] == null);
    d.onSelect(); Test.assert(v.coordinateValues()[0] == 89 && v.coordinateValues()[1] == -170);
    d.onBack(); d.onBack(); d.onNextPage(); d.onSelect(); d.onNextPage();
    Test.assert(v.page == :coordinates && !v.rawCoordinates && v.coordinateValues()[0] == null);
    s.stop();
    return true;
}

(:test)
function walkingAndSlowWalkingRemainResponsive(logger) {
    var speeds = [0.35, 1.4, 4.0, 12.0];
    for (var n = 0; n < speeds.size(); n++) {
        var g = new GpsState(); var speed = speeds[n];
        for (var i = 0; i <= 120; i++) { Synthetic.fix(g, i * speed, i, speed); }
        var lag = Geo.distance(g.xy, Geo.project(52.0d + 120 * speed / 111319.49d, 5), 52);
        Test.assert(lag < Geo.max(5, 3 * speed));
        Test.assert(g.distance > 120 * speed * 0.85);
        Test.assert(g.distance < 120 * speed * 1.02);
    }
    return true;
}

(:test)
function unknownSpeedStillWalks(logger) {
    var g = new GpsState();
    for (var i = 0; i <= 60; i++) { Synthetic.fix(g, i * 0.5, i, null); }
    Test.assert(g.distance > 25 && g.distance < 31);
    return true;
}

(:test)
function isolatedAndPersistentJumps(logger) {
    var g = new GpsState();
    for (var i = 0; i < 10; i++) { Synthetic.fix(g, 0, i, 0.0); }
    Synthetic.fix(g, 500, 10, 0.0); Synthetic.fix(g, 0, 11, 0.0); Synthetic.fix(g, 0, 12, 0.0);
    Test.assert(g.count == 1 && g.distance == 0);
    for (var j = 13; j < 18; j++) { Synthetic.fix(g, 500, j, 0.0); }
    Test.assert(g.count == 2 && g.point(1)[3]);
    Test.assert(g.distance == 0);
    Test.assert(Geo.distance(g.xy, Geo.project(52.0d + 500 / 111319.49d, 5), 52) < 1);
    return true;
}

(:test)
function ordinarySpikeMedianRejection(logger) {
    var g = new GpsState();
    for (var i = 0; i < 10; i++) { Synthetic.fix(g, 0, i, 0.0); }
    Synthetic.fix(g, 25, 10, 0.0); Synthetic.fix(g, 0, 11, 0.0); Synthetic.fix(g, 0, 12, 0.0);
    Test.assert(g.count == 1 && g.distance == 0);
    return true;
}

(:test)
function gapsDoNotAccumulateTeleportDistance(logger) {
    var g = new GpsState();
    for (var i = 0; i < 20; i++) { Synthetic.fix(g, i * 2, i, 2.0); }
    var distance = g.distance;
    Synthetic.fix(g, 500, 40, 0.0);
    Test.assert(g.point(g.count - 1)[3] && g.distance == distance);
    g.gap = true; Synthetic.fix(g, 1000, 41, 0.0);
    Test.assert(g.point(g.count - 1)[3] && g.distance == distance);
    return true;
}

(:test)
function movementAcrossDateLine(logger) {
    var g = new GpsState();
    for (var i = 0; i < 30; i++) {
        var lon = 179.9999d + i * 0.00002d;
        if (lon > 180) { lon -= 360; }
        g.accept(0.0d, lon, 100 + i, Position.QUALITY_GOOD, 2.2, 100 + i, i * 1000);
    }
    Test.assert(g.distance > 50 && g.distance < 70);
    Test.assert(g.filter.outliers == 0);
    return true;
}

(:test)
function stopThenResumeMoving(logger) {
    var g = new GpsState();
    for (var i = 0; i < 30; i++) { Synthetic.fix(g, i, i, 1.0); }
    for (var j = 30; j < 70; j++) { Synthetic.fix(g, 29, j, 0.0); }
    var points = g.count; var distance = g.distance;
    for (var k = 70; k < 130; k++) { Synthetic.fix(g, 29 + (k % 3) - 1, k, 0.0); }
    Test.assert(g.count == points && Geo.abs(g.distance - distance) < 0.1);
    for (var n = 130; n < 160; n++) { Synthetic.fix(g, 29 + (n - 130), n, 1.0); }
    Test.assert(g.distance > distance + 20);
    return true;
}

(:test)
function gridZoomPanAndLimits(logger) {
    var m = new GridState();
    m.recenter(Geo.project(52, 5));
    for (var i = 0; i < 30; i++) { m.changeZoom(-1); }
    Test.assert(m.zoom == 10);
    for (var j = 0; j < 30; j++) { m.changeZoom(1); }
    Test.assert(m.zoom == 19);
    m.pan(65, 65); var x = m.center[0];
    m.track(Geo.project(0, 0)); Test.assert(m.center[0] == x && !m.follow);
    m.recenter(Geo.project(0, 179.999d)); m.pan(10000, 100000000);
    Test.assert(m.center[0] >= -Geo.WORLD / 2 && m.center[0] <= Geo.WORLD / 2);
    Test.assert(m.center[1] == Geo.WORLD / 2);
    for (var span = 0.00001d; span < 10; span *= 2) {
        var step = Geo.gridStep(span / 5); Test.assert(span / step <= 5.01);
    }
    return true;
}

(:test)
function boundedLongTraceAndRepeatedSessions(logger) {
    var maximum = 0; var afterWarmup = 0;
    for (var run = 0; run < 30; run++) {
        var g = new GpsState();
        for (var i = 0; i < 1000; i++) { Synthetic.fix(g, i * 2, i, 2.0); }
        Test.assert(g.count == 180 && g.head < 180);
        var memory = System.getSystemStats().usedMemory;
        maximum = Geo.max(maximum, memory);
        if (run == 3) { afterWarmup = memory; }
        if (run > 3) { Test.assert(memory <= afterWarmup + 1024); }
    }
    logger.debug("SYNTHETIC 30 sessions / 30000 fixes; peak measured heap bytes: " + maximum);
    return true;
}

(:test)
function homeDoesNotStartGpsAndStopReleases(logger) {
    var s = new FieldSession();
    Test.assert(!s.running && !s.subscribed && s.ticker == null);
    Test.assert(s.start());
    s.stop();
    Test.assert(!s.running && !s.subscribed && s.ticker == null && s.gps.count == 0 && s.grid.center == null);
    s.active(); Test.assert(!s.subscribed && s.ticker == null);
    return true;
}

(:test)
function englishTextAndRoundScreenFit(logger) {
    var s = new FieldSession(); var v = new FieldView(s); v.fonts();
    var bitmap = Graphics.createBufferedBitmap({:width => 390, :height => 390}); var dc = bitmap.get().getDc();
    Test.assert(dc.getTextWidthInPixels("-179.999999", Graphics.FONT_SMALL) < 335);
    Test.assert(dc.getTextWidthInPixels("Center -85.05113 / -179.99999", v.tinyFont) < 313);
    Test.assert(dc.getTextWidthInPixels("UP/DN Zoom  START Menu", v.tinyFont) < 218);
    Test.assert(dc.getTextWidthInPixels("Nothing saved or shared", v.tinyFont) < 285);
    Test.assert(dc.getTextWidthInPixels("FILTERED / WGS84", v.smallFont) < 270);
    Test.assert(dc.getTextWidthInPixels("START: Filtered", v.tinyFont) < 218);
    Test.assert(dc.getTextWidthInPixels("Polar limit: use Raw", v.smallFont) < 290);
    Test.assert(dc.getTextWidthInPixels("Network OFF / Storage OFF", v.smallFont) < 355);
    Test.assert(dc.getTextWidthInPixels("Motion UNAVAILABLE", v.smallFont) < 335);
    Test.assert(dc.getTextWidthInPixels("START: Motion off", v.tinyFont) < 290);
    var pages = [:home, :menu, :coordinates, :stats, :diagnostics, :finish, :grid, :pan];
    Synthetic.fix(s.gps, 0, 0, 0.0); s.grid.recenter(s.gps.xy);
    for (var theme = 0; theme < 2; theme++) {
        s.grid.night = theme == 1;
        for (var i = 0; i < pages.size(); i++) { v.page = pages[i]; v.onUpdate(dc); }
        v.page = :coordinates; v.rawCoordinates = true; v.onUpdate(dc); v.rawCoordinates = false;
    }
    logger.debug("All English pages rendered, both themes; screenshot review separate");
    return true;
}

(:test)
function redrawStressAndSharpTurn(logger) {
    var s = new FieldSession(); var v = new FieldView(s); v.page = :grid;
    var bitmap = Graphics.createBufferedBitmap({:width => 390, :height => 390}); var dc = bitmap.get().getDc();
    var warmed = 0; var peak = 0;
    for (var i = 0; i < 1000; i++) {
        var north = Geo.min(i, 400) * 1.4 / 111319.49d;
        var east = Geo.max(0, i - 400) * 1.4 / (111319.49d * Math.cos(52 * Geo.PI / 180));
        s.gps.accept(52.0d + north, 5.0d + east, 100 + i, Position.QUALITY_GOOD, 1.4, 100 + i, i * 1000);
        s.grid.track(s.gps.xy); v.onUpdate(dc);
        var memory = System.getSystemStats().usedMemory; peak = Geo.max(peak, memory);
        if (i == 600) { warmed = memory; }
        if (i > 600) { Test.assert(memory < warmed + 1024); }
    }
    Test.assert(s.gps.distance > 1370 && s.gps.distance < 1410);
    Test.assert(s.gps.count == 180);
    logger.debug("SYNTHETIC 1000 redraws + 90-degree turn; heap peak bytes: " + peak);
    return true;
}

(:test)
function noPersistentPreferencesOrGpsData(logger) {
    Application.Storage.setValue("grid-preferences-v1", {"zoom" => 12});
    Application.Storage.setValue("preferences-v1", {"zoom" => 15});
    Application.Storage.setValue("g0-probe", "test");
    var s = new FieldSession();
    Test.assert(Application.Storage.getValue("grid-preferences-v1") == null);
    Test.assert(Application.Storage.getValue("preferences-v1") == null);
    Test.assert(Application.Storage.getValue("g0-probe") == null);
    Test.assert(s.start()); s.grid.zoom = 12; s.stop();
    Test.assert(Application.Storage.getValue("grid-preferences-v1") == null);
    var next = new FieldSession(); Test.assert(next.grid.zoom == 17);
    Test.assert(next.gps.count == 0 && next.gps.lat == null);
    logger.debug("No application persistence: old keys removed; grid-only session creates no preferences/GPS history");
    return true;
}

(:test)
function repeatedGpsLifecycleDoesNotRetainTrace(logger) {
    var s = new FieldSession(); var warmed = 0; var peakAfterStop = 0;
    for (var run = 0; run < 40; run++) {
        Test.assert(s.start());
        for (var i = 0; i < 300; i++) { Synthetic.fix(s.gps, i * 2, i, 2.0); }
        s.stop();
        Test.assert(s.gps.count == 0 && !s.subscribed && s.ticker == null);
        var memory = System.getSystemStats().usedMemory;
        peakAfterStop = Geo.max(memory, peakAfterStop);
        if (run == 5) { warmed = memory; }
        if (run > 5) { Test.assert(memory <= warmed + 512); }
    }
    logger.debug("40 GPS start/stop cycles / 12000 fixes; peak post-stop heap bytes: " + peakAfterStop);
    return true;
}

(:test)
function pauseResumeAndExitStayEphemeral(logger) {
    var s = new FieldSession();
    Test.assert(!s.resume()); Test.assert(s.start());
    var timer = s.ticker;
    Test.assert(!s.start() && s.resume() && s.ticker == timer);
    Synthetic.fix(s.gps, 0, 0, 0.0);
    s.startedMs = System.getTimer() - 5000;
    s.pause();
    Test.assert(!s.running && s.opened && !s.subscribed && s.ticker == null);
    Test.assert(s.seconds() >= 5 && s.seconds() < 6 && s.gps.count == 1);
    var pausedTime = s.seconds();
    s.pause(); s.active();
    Test.assert(s.seconds() == pausedTime && s.ticker == null && !s.subscribed);
    Test.assert(s.resume() && s.gps.gap);
    s.inactive(); Test.assert(s.running && !s.subscribed && s.ticker == null);
    s.active(); Test.assert(s.running && s.subscribed && s.ticker != null);
    s.stop(); s.active(); s.stop();
    Test.assert(!s.opened && !s.running && !s.subscribed && s.ticker == null);
    Test.assert(s.gps.lat == null && s.gps.count == 0 && s.distance() == 0 && s.seconds() == 0);
    return true;
}

(:test)
function buttonFlowHasOnlyLocalSessions(logger) {
    var s = new FieldSession(); var v = new FieldView(s); var d = new FieldDelegate(v, s);
    d.onPreviousPage(); Test.assert(!s.opened && v.page == :home);
    d.onSelect(); Test.assert(s.running && v.page == :grid);
    d.onBack(); Test.assert(!s.running && v.page == :finish && v.selection == 0);
    d.onSelect(); Test.assert(s.running && v.page == :grid);
    d.onBack(); d.onNextPage(); d.onSelect();
    Test.assert(v.page == :home && !s.opened && s.gps.count == 0);
    d.onNextPage(); Test.assert(v.page == :coordinates && s.running);
    d.onBack(); d.onBack(); d.onNextPage(); d.onSelect();
    Test.assert(!s.opened && v.page == :home && !d.onBack());
    return true;
}

(:test)
function liveSpeedRequiresFreshFilteredPosition(logger) {
    var s = new FieldSession(); Test.assert(s.start());
    Test.assert(s.speed() == null);
    Synthetic.fix(s.gps, 0, 0, 0.0); s.gps.receivedMs = System.getTimer();
    Test.assert(s.speed() == 0);
    s.gps.filter.moving = true; s.gps.speed = 1.4;
    Test.assert(s.speed() == 1.4);
    s.gps.filter.status = "REACQUIRE"; Test.assert(s.speed() == null);
    s.gps.filter.status = "MOVING"; s.gps.quality = Position.QUALITY_POOR;
    Test.assert(s.speed() == null);
    s.pause(); Test.assert(s.speed() == null); s.stop();
    return true;
}
