import Toybox.Graphics;
import Toybox.Position;
import Toybox.Math;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class FieldView extends WatchUi.View {
    var session as FieldSession;
    var page = :home;
    var selection = 0;
    var panAxis = 0;
    var menuItems as Array;
    var smallFont = null;
    var tinyFont = null;
    var fontsReady = false;
    var rawCoordinates = false;

    function initialize(s) {
        View.initialize(); session = s;
        menuItems = ["Follow position", "Browse grid", "Live stats", "GPS coordinates",
            "Day / night", "Diagnostics", "Retry GPS", "Pause / end"];
    }
    function fonts() {
        if (fontsReady) { return; } fontsReady = true;
        try {
            smallFont = Graphics.getVectorFont({:face => ["RobotoCondensedRegular", "RobotoRegular"], :size => 24});
            tinyFont = Graphics.getVectorFont({:face => ["RobotoCondensedRegular", "RobotoRegular"], :size => 18});
        } catch (e) {}
        if (smallFont == null) { smallFont = Graphics.FONT_XTINY; }
        if (tinyFont == null) { tinyFont = Graphics.FONT_XTINY; }
    }
    function line(dc, y, text, color, font) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }
    function status() {
        var g = session.gps;
        if (!session.running) { return "PAUSED"; }
        if (g.lat == null) { return "Waiting for GPS"; }
        if (!g.usable(System.getTimer())) { return "GPS stale / weak"; }
        return (g.quality == Position.QUALITY_GOOD ? "GOOD" : "USABLE") + " / " + g.filter.status;
    }
    function coordinateValues() as Array {
        var g = session.gps;
        if (rawCoordinates) { return [g.lat, g.lon]; }
        return g.xy == null ? [null, null] : Geo.inverse(g.xy[0], g.xy[1]);
    }
    function onUpdate(dc as Graphics.Dc) as Void {
        fonts();
        var g = session.gps; var m = session.grid;
        var bg = m.night ? 0x102128 : 0xEDF3EE;
        var ink = m.night ? 0xEDF5EF : 0x193E38;
        dc.setColor(ink, bg); dc.clear();
        if (page == :home) {
            line(dc, 43, "FIELDGRID", ink, Graphics.FONT_SMALL);
            line(dc, 104, "OFFLINE GPS / G0", ink, smallFont);
            line(dc, 155, "Nothing saved or shared", ink, smallFont);
            line(dc, 211, "START: Open grid", ink, smallFont);
            line(dc, 247, "DOWN: Coordinates", ink, smallFont);
            line(dc, 290, session.lastResult == null ? "GPS starts on your action" : session.lastResult, ink, tinyFont);
            line(dc, 323, session.error == null ? "BACK: Exit" : session.error, ink, tinyFont);
            return;
        }
        if (page == :menu) {
            line(dc, 40, "FIELDGRID", ink, Graphics.FONT_SMALL);
            var first = (selection / 4) * 4;
            for (var j = 0; j < 4; j++) {
                var index = first + j;
                if (index >= menuItems.size()) { break; }
                var y = 104 + j * 46;
                if (index == selection) {
                    dc.setColor(0x187C69, Graphics.COLOR_TRANSPARENT); dc.fillRoundedRectangle(51, y - 5, 288, 42, 12);
                }
                line(dc, y, menuItems[index], index == selection ? 0xFFFFFF : ink, smallFont);
            }
            line(dc, 303, (selection + 1) + " / " + menuItems.size(), ink, smallFont);
            line(dc, 338, "BACK: Grid", ink, tinyFont); return;
        }
        if (page == :finish) {
            line(dc, 45, "SESSION PAUSED", ink, smallFont);
            line(dc, 110, Geo.timeText(session.seconds()) + " / " + Geo.distanceText(session.distance()), ink, smallFont);
            line(dc, 155, "End clears this session", ink, tinyFont);
            var choices = ["Resume", "End session"];
            for (var k = 0; k < choices.size(); k++) {
                var yy = 209 + k * 47;
                if (selection == k) { dc.setColor(0x187C69, Graphics.COLOR_TRANSPARENT); dc.fillRoundedRectangle(53, yy - 4, 284, 38, 10); }
                line(dc, yy, choices[k], selection == k ? 0xFFFFFF : ink, smallFont);
            }
            line(dc, 334, "START: Select", ink, tinyFont); return;
        }
        if (page == :coordinates) {
            var ll = coordinateValues();
            line(dc, 40, rawCoordinates ? "RAW GPS / WGS84" : "FILTERED / WGS84", ink, smallFont);
            line(dc, 80, status(), ink, smallFont);
            line(dc, 123, "Latitude", ink, smallFont);
            line(dc, 154, Geo.displayCoordinate(ll[0]), ink, Graphics.FONT_SMALL);
            line(dc, 215, "Longitude", ink, smallFont);
            line(dc, 246, Geo.displayCoordinate(ll[1]), ink, Graphics.FONT_SMALL);
            var age = g.age(System.getTimer());
            line(dc, 297, age == null ? "No fix yet" : (!rawCoordinates && g.xy == null ? "Polar limit: use Raw" :
                "Fix age " + Geo.min(9999, age).toNumber() + "s"), ink, smallFont);
            line(dc, 329, rawCoordinates ? "START: Filtered" : "START: Raw", ink, tinyFont);
            line(dc, 353, "BACK: Grid", ink, tinyFont); return;
        }
        if (page == :stats) {
            line(dc, 38, "LIVE STATS", ink, smallFont);
            line(dc, 75, status(), ink, tinyFont);
            line(dc, 103, Geo.timeText(session.seconds()), ink, Graphics.FONT_SMALL);
            line(dc, 163, Geo.distanceText(session.distance()), ink, Graphics.FONT_SMALL);
            var speed = session.speed();
            line(dc, 222, speed == null ? "Speed --" : (speed * 3.6).format("%.1f") + " km/h", ink, smallFont);
            var pace = speed != null && speed >= 0.3 ? Geo.timeText(1000 / speed) + " /km" : "-- /km";
            line(dc, 257, pace, ink, smallFont);
            line(dc, 303, "Filtered distance estimate", ink, tinyFont);
            line(dc, 338, "BACK: Grid", ink, tinyFont); return;
        }
        if (page == :diagnostics) {
            line(dc, 42, "DIAGNOSTICS", ink, smallFont);
            line(dc, 83, "v0.2.3 / fr165 / G0", ink, smallFont);
            line(dc, 119, "Network OFF / Storage OFF", ink, smallFont);
            var stats = System.getSystemStats();
            session.peakMemory = Geo.max(session.peakMemory, stats.usedMemory);
            line(dc, 155, "RAM " + (stats.usedMemory / 1024) + " / peak " + (session.peakMemory / 1024) + " KiB", ink, smallFont);
            line(dc, 191, "Trace " + g.count + "/180 / GPS " + session.updateCount, ink, smallFont);
            line(dc, 227, "Filter " + g.filter.status, ink, smallFont);
            line(dc, 263, "Motion " + session.motion.label(System.getTimer()), ink, smallFont);
            line(dc, 301, session.error == null ? (session.motion.enabled ? "START: Motion off" : "START: Motion on") : session.error, ink, tinyFont);
            line(dc, 338, "BACK: Grid", ink, tinyFont); return;
        }
        if (m.center == null || (g.lat != null && g.xy == null && m.follow)) {
            line(dc, 156, g.lat != null && g.xy == null ? "Polar grid limit" : "Waiting for GPS", ink, smallFont);
            line(dc, 199, g.lat != null ? "Coordinates in menu" : "Go outdoors for a fix", ink, smallFont);
        } else {
            drawGrid(dc, bg, ink);
        }
        dc.setColor(bg, Graphics.COLOR_TRANSPARENT); dc.fillRectangle(42, 32, 306, 61);
        line(dc, 36, page == :pan ? (panAxis == 0 ? "PAN EAST / WEST" : "PAN NORTH / SOUTH") : "GPS GRID / NORTH UP", ink, smallFont);
        line(dc, 68, session.error == null ? status() : session.error, ink, tinyFont);
        dc.setColor(bg, Graphics.COLOR_TRANSPARENT); dc.fillRectangle(40, 295, 310, 64);
        if (m.center != null) {
            var ll = Geo.inverse(m.center[0], m.center[1]);
            line(dc, 298, "Center " + ll[0].format("%.5f") + " / " + ll[1].format("%.5f"), ink, tinyFont);
        }
        line(dc, 321, Geo.timeText(session.seconds()) + " / " + Geo.distanceText(session.distance()), ink, smallFont);
        line(dc, 355, page == :pan ? "START Axis  BACK Follow" : "UP/DN Zoom  START Menu", ink, tinyFont);
    }
    function drawGrid(dc, bg, ink) {
        var m = session.grid; var g = session.gps;
        var box = Geo.bounds(m.center[0], m.center[1], m.zoom);
        var c = Geo.inverse(m.center[0], m.center[1]);
        var west = box[0] / Geo.R * 180 / Geo.PI; var east = box[2] / Geo.R * 180 / Geo.PI;
        var south = Geo.inverse(0, Geo.max(-Geo.WORLD / 2, box[1]))[0];
        var north = Geo.inverse(0, Geo.min(Geo.WORLD / 2, box[3]))[0];
        var lonStep = Geo.gridStep((east - west) / 5);
        var latStep = Geo.gridStep((north - south) / 5);
        dc.setColor(m.night ? 0x365551 : 0xB7CDC0, Graphics.COLOR_TRANSPARENT);
        var v = Math.ceil(west / lonStep) * lonStep;
        for (var i = 0; i < 8 && v <= east; i++, v += lonStep) {
            var x = (v * Geo.PI / 180 * Geo.R - box[0]) / Geo.resolution(m.zoom);
            dc.setColor(m.night ? 0x365551 : 0xB7CDC0, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x, 90, x, 294);
            if (x > 80 && x < 310) {
                var lon = v > 180 ? v - 360 : (v < -180 ? v + 360 : v);
                dc.setColor(ink, Graphics.COLOR_TRANSPARENT);
                dc.drawText(x, 96, tinyFont, lon.format("%.4f"), Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
        v = Math.ceil(south / latStep) * latStep;
        for (var j = 0; j < 8 && v <= north; j++, v += latStep) {
            var y = (box[3] - Geo.project(v, 0)[1]) / Geo.resolution(m.zoom);
            if (y < 120 || y > 275) { continue; }
            dc.setColor(m.night ? 0x365551 : 0xB7CDC0, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(0, y, 390, y);
            dc.setColor(ink, Graphics.COLOR_TRANSPARENT);
            dc.drawText(33, y + 2, tinyFont, v.format("%.4f"), Graphics.TEXT_JUSTIFY_LEFT);
        }
        dc.setClip(20, 117, 350, 164);
        dc.setColor(0xDD863B, Graphics.COLOR_TRANSPARENT); dc.setPenWidth(3);
        var prev = null as Array or Null;
        for (var n = 0; n < g.count; n++) {
            var p = g.point(n); var pixel = Geo.pixel(p[0], p[1], box, 390);
            if (prev != null && !p[3] && Geo.abs(pixel[0]) < 4000 && Geo.abs(pixel[1]) < 4000 &&
                Geo.abs(prev[0]) < 4000 && Geo.abs(prev[1]) < 4000) { dc.drawLine(prev[0], prev[1], pixel[0], pixel[1]); }
            prev = pixel;
        }
        dc.setPenWidth(1);
        // Crosshair is the exact center coordinate, independent of the filtered blue marker.
        dc.setColor(ink, Graphics.COLOR_TRANSPARENT); dc.drawLine(188, 195, 202, 195); dc.drawLine(195, 188, 195, 202);
        if (g.xy != null) {
            var pos = Geo.pixel(g.xy[0], g.xy[1], box, 390);
            if (pos[0] > 10 && pos[0] < 380 && pos[1] > 115 && pos[1] < 282) {
                dc.setColor(bg, Graphics.COLOR_TRANSPARENT); dc.fillCircle(pos[0], pos[1], 12);
                dc.setColor(g.usable(System.getTimer()) && !"REACQUIRE".equals(g.filter.status) ? 0x247BCD : 0x84928E, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(pos[0], pos[1], 8); dc.drawCircle(pos[0], pos[1], 12);
            }
        }
        dc.clearClip();
        dc.setColor(bg, Graphics.COLOR_TRANSPARENT); dc.fillRectangle(104, 265, 182, 30);
        dc.setColor(ink, Graphics.COLOR_TRANSPARENT); dc.drawLine(165, 270, 225, 270);
        var meters = Geo.resolution(m.zoom) * Math.cos(c[0] * Geo.PI / 180) * 60;
        line(dc, 275, Geo.distanceText(meters) + " / z" + m.zoom, ink, tinyFont);
    }
}

class FieldDelegate extends WatchUi.BehaviorDelegate {
    var view as FieldView;
    var session as FieldSession;
    function initialize(v, s) { BehaviorDelegate.initialize(); view = v; session = s; }
    function refresh() { WatchUi.requestUpdate(); return true; }
    function onNextPage() as Boolean { return move(1); }
    function onPreviousPage() as Boolean { return move(-1); }
    function move(delta) {
        var p = view.page;
        if (p == :home) {
            if (delta > 0 && session.start()) { view.rawCoordinates = false; view.page = :coordinates; }
        } else if (p == :menu) { view.selection = (view.selection + delta + 8) % 8; }
        else if (p == :finish) { view.selection = (view.selection + delta + 2) % 2; }
        else if (p == :pan) { session.grid.pan(view.panAxis == 0 ? delta * 65 : 0, view.panAxis == 1 ? -delta * 65 : 0); }
        else if (p == :grid) { session.grid.changeZoom(-delta); }
        return refresh();
    }
    function onSelect() as Boolean {
        var p = view.page;
        if (p == :home) { if (session.start()) { view.rawCoordinates = false; view.page = :grid; } }
        else if (p == :grid) { view.page = :menu; view.selection = 0; }
        else if (p == :pan) { view.panAxis = 1 - view.panAxis; }
        else if (p == :coordinates) { view.rawCoordinates = !view.rawCoordinates; }
        else if (p == :diagnostics) { session.toggleMotion(); }
        else if (p == :menu) {
            var i = view.selection;
            if (i == 0) { session.grid.recenter(session.gps.xy); view.page = :grid; }
            if (i == 1) { session.grid.follow = false; view.page = :pan; }
            if (i == 2) { view.page = :stats; }
            if (i == 3) { view.page = :coordinates; }
            if (i == 4) { session.grid.night = !session.grid.night; view.page = :grid; }
            if (i == 5) { view.page = :diagnostics; }
            if (i == 6) { session.enableGps(); view.page = :grid; }
            if (i == 7) { finishPage(); }
        } else if (p == :finish) {
            if (view.selection == 0 && session.resume()) { view.page = :grid; }
            else if (view.selection == 1) { session.stop(); view.page = :home; }
        }
        return refresh();
    }
    function finishPage() {
        session.pause(); view.page = :finish; view.selection = 0;
    }
    function onBack() as Boolean {
        var p = view.page;
        if (p == :home) { return false; }
        if (p == :grid) { finishPage(); }
        else if (p == :finish) { if (session.resume()) { view.page = :grid; } }
        else { if (p == :pan) { session.grid.recenter(session.gps.xy); } view.page = :grid; }
        return refresh();
    }
}
