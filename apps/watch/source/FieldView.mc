import Toybox.Graphics;
import Toybox.Math;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Position;

function textResource(id) { return WatchUi.loadResource(id); }

class FieldView extends WatchUi.View {
    var session as FieldSession;
    var page = :home;
    var selection = 0;
    var panAxis = 0;
    var menuItems as Array;

    function initialize(s) {
        View.initialize(); session = s;
        menuItems = [Rez.Strings.Follow, Rez.Strings.Browse, Rez.Strings.Theme,
            Rez.Strings.Profile, Rez.Strings.Diagnostics, Rez.Strings.StorageTest,
            Rez.Strings.Retry, Rez.Strings.Stop];
    }

    function line(dc, y, text, color, font) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(195, y, font, text, Graphics.TEXT_JUSTIFY_CENTER);
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var m = session.map; var gps = session.gps;
        var night = "night".equals(m.style);
        var bg = night ? 0x102128 : 0xEAF0E9;
        var ink = night ? 0xEEF4EE : 0x193E38;
        dc.setColor(ink, bg); dc.clear();
        if (page == :home) {
            line(dc, 43, "FIELDMAP", ink, Graphics.FONT_SMALL);
            line(dc, 96, "FORERUNNER 165 / G0", 0x63867A, Graphics.FONT_XTINY);
            line(dc, 141, textResource(Rez.Strings.Consent1), ink, Graphics.FONT_XTINY);
            line(dc, 173, textResource(Rez.Strings.Consent2), ink, Graphics.FONT_XTINY);
            line(dc, 205, textResource(Rez.Strings.Consent3), ink, Graphics.FONT_XTINY);
            line(dc, 237, textResource(Rez.Strings.Consent4), ink, Graphics.FONT_XTINY);
            dc.setColor(0x187C69, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(83, 280, 224, 48, 24);
            line(dc, 287, textResource(Rez.Strings.OpenMap), 0xFFFFFF, Graphics.FONT_XTINY);
            line(dc, 337, "START", ink, Graphics.FONT_XTINY);
            return;
        }
        if (page == :menu) {
            line(dc, 37, "FIELDMAP", ink, Graphics.FONT_SMALL);
            var first = selection < 4 ? 0 : 4;
            for (var j = 0; j < 4; j++) {
                var index = first + j;
                var y = 94 + j * 48;
                if (index == selection) {
                    dc.setColor(0x187C69, Graphics.COLOR_TRANSPARENT);
                    dc.fillRoundedRectangle(53, y, 284, 45, 15);
                }
                line(dc, y + 3, textResource(menuItems[index]), index == selection ? 0xFFFFFF : ink, Graphics.FONT_SMALL);
            }
            line(dc, 305, (selection + 1).toString() + " / 8", ink, Graphics.FONT_XTINY);
            line(dc, 338, textResource(Rez.Strings.Back), ink, Graphics.FONT_XTINY);
            return;
        }
        if (page == :diagnostics) {
            line(dc, 45, textResource(Rez.Strings.Diagnostics), ink, Graphics.FONT_XTINY);
            var stats = System.getSystemStats();
            line(dc, 83, "v0.1.0 / G0", ink, Graphics.FONT_XTINY);
            line(dc, 115, "Phone: " + (System.getDeviceSettings().phoneConnected ? "YES" : "NO"), ink, Graphics.FONT_XTINY);
            line(dc, 147, "Last code: " + m.lastCode, ink, Graphics.FONT_XTINY);
            line(dc, 179, "RAM " + (stats.usedMemory / 1024) + " / peak " + (session.peakMemory / 1024) + " KiB", ink, Graphics.FONT_XTINY);
            line(dc, 211, "Images " + m.requestCount + " / " + m.lastDuration + " ms", ink, Graphics.FONT_XTINY);
            line(dc, 243, "Trace " + gps.count + " / GPS " + session.updateCount, ink, Graphics.FONT_XTINY);
            line(dc, 275, "Store: " + session.storageStatus, ink, Graphics.FONT_XTINY);
            line(dc, 325, textResource(Rez.Strings.Back), ink, Graphics.FONT_XTINY);
            return;
        }
        if (m.center == null) {
            line(dc, 154, textResource(Rez.Strings.Waiting), ink, Graphics.FONT_SMALL);
            line(dc, 205, "Go outside / START menu", ink, Graphics.FONT_XTINY);
            drawStatus(dc, ink, bg); return;
        }
        var box = Geo.bounds(m.center[0], m.center[1], m.zoom);
        var rasterVisible = false;
        if (m.bitmap != null && m.metadata != null) {
            // Display old raster in its original geographic frame until the new one commits.
            var old = m.metadata["bounds3857"] as Array;
            var topLeft = Geo.pixel(old[0], old[3], box, 390);
            var width = (old[2] - old[0]) / (box[2] - box[0]) * 390;
            if (topLeft[0] < 390 && topLeft[1] < 390 && topLeft[0] + width > 0 && topLeft[1] + width > 0) {
                var transform = new Graphics.AffineTransform();
                var raster = m.bitmap instanceof Graphics.BitmapReference ? m.bitmap.get() : m.bitmap;
                var factor = width / raster.getWidth();
                transform.scale(factor, factor);
                dc.drawBitmap2(topLeft[0], topLeft[1], m.bitmap, {:transform => transform});
                rasterVisible = true;
            }
        }
        if (session.baseUrl.length() == 0) { drawGrid(dc, box, night); }
        dc.setPenWidth(4);
        dc.setColor(0xE29341, Graphics.COLOR_TRANSPARENT);
        var previous = null as Array or Null;
        for (var i = 0; i < gps.count; i++) {
            var point = gps.point(i);
            var p = Geo.pixel(point[0], point[1], box, 390);
            if (previous != null && !point[3] && Geo.abs(p[0]) < 2000 && Geo.abs(p[1]) < 2000 &&
                Geo.abs(previous[0]) < 2000 && Geo.abs(previous[1]) < 2000) {
                dc.drawLine(previous[0], previous[1], p[0], p[1]);
            }
            previous = p;
        }
        dc.setPenWidth(1);
        if (gps.xy != null) {
            var pos = Geo.pixel(gps.xy[0], gps.xy[1], box, 390);
            if (pos[0] >= 0 && pos[0] <= 390 && pos[1] >= 0 && pos[1] <= 390) {
                dc.setColor(0xFFFFFF, Graphics.COLOR_TRANSPARENT); dc.fillCircle(pos[0], pos[1], 13);
                dc.setColor(gps.usable(System.getTimer()) ? 0x156DCE : 0x838B8C, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(pos[0], pos[1], 9);
                dc.setPenWidth(3); dc.drawCircle(pos[0], pos[1], 18); dc.setPenWidth(1);
                if (gps.heading != null) {
                    var sx = Math.sin(gps.heading); var sy = -Math.cos(gps.heading);
                    dc.fillPolygon([[pos[0] + sx * 29, pos[1] + sy * 29],
                        [pos[0] + sx * 18 - sy * 6, pos[1] + sy * 18 + sx * 6],
                        [pos[0] + sx * 18 + sy * 6, pos[1] + sy * 18 - sx * 6]]);
                }
            }
        }
        // Ground scale includes latitude; raster dimensions do not alter the geographic box.
        var ll = Geo.inverse(m.center[0], m.center[1]);
        var meters = Geo.resolution(m.zoom) * Math.cos(ll[0] * Geo.PI / 180.0d) * 60;
        dc.setColor(ink, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(3); dc.drawLine(163, 287, 223, 287); dc.setPenWidth(1);
        line(dc, 291, meters.format("%.0f") + " m / z" + m.zoom, ink, Graphics.FONT_XTINY);
        drawStatus(dc, ink, bg);
        if (page == :pan) {
            line(dc, 237, textResource(panAxis == 0 ? Rez.Strings.NorthSouth : Rez.Strings.EastWest), ink, Graphics.FONT_XTINY);
        } else if (session.baseUrl.length() != 0 && !rasterVisible && !m.busy) {
            line(dc, 233, textResource(Rez.Strings.NoMap), ink, Graphics.FONT_XTINY);
        }
    }

    function drawGrid(dc, box as Array, night) {
        dc.setColor(night ? 0x314A4B : 0xC5D5CA, Graphics.COLOR_TRANSPARENT);
        var step = session.map.zoom >= 15 ? 100 : 200;
        var start = Math.ceil(box[0] / step).toNumber();
        var end = Math.floor(box[2] / step).toNumber();
        for (var x = start; x <= end; x++) {
            var p = Geo.pixel(x * step, box[3], box, 390);
            dc.drawLine(p[0], 0, p[0], 390);
        }
        start = Math.ceil(box[1] / step).toNumber(); end = Math.floor(box[3] / step).toNumber();
        for (var y = start; y <= end; y++) {
            var p2 = Geo.pixel(box[0], y * step, box, 390);
            dc.drawLine(0, p2[1], 390, p2[1]);
        }
    }

    function drawStatus(dc, ink, bg) {
        var g = session.gps; var m = session.map;
        var age = g.age(System.getTimer());
        var status = textResource(Rez.Strings.Waiting);
        if (age != null) {
            status = age > 5 ? textResource(Rez.Strings.Stale) :
                (g.quality == Position.QUALITY_GOOD ? textResource(Rez.Strings.Good) :
                (g.quality == Position.QUALITY_USABLE ? textResource(Rez.Strings.Usable) : textResource(Rez.Strings.Weak)));
            status += " / " + Geo.min(9999, age).toNumber() + "s";
        }
        dc.setColor(bg, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(56, 34, 278, 45, 18);
        line(dc, 42, status, ink, Graphics.FONT_XTINY);
        line(dc, 82, "N", ink, Graphics.FONT_XTINY);
        var network = textResource(Rez.Strings.Offline);
        if (session.configError || m.permanent) { network = textResource(Rez.Strings.SettingsIssue); }
        else if (m.lastCode != 0) { network = textResource(Rez.Strings.ServiceIssue); }
        else if (session.baseUrl.length() != 0 && (m.busy || m.wanted)) { network = textResource(Rez.Strings.Loading); }
        else if (session.baseUrl.length() != 0) { network = "Raster / " + m.size + " px"; }
        dc.setColor(bg, Graphics.COLOR_TRANSPARENT); dc.fillRectangle(49, 326, 292, 29);
        line(dc, 326, network, ink, Graphics.FONT_XTINY);
        line(dc, 105, textResource(Rez.Strings.Synthetic), ink, Graphics.FONT_XTINY);
    }
}

class FieldDelegate extends WatchUi.BehaviorDelegate {
    var view; var session as FieldSession;
    function initialize(v, s) { BehaviorDelegate.initialize(); view = v; session = s; }
    function redraw() { WatchUi.requestUpdate(); return true; }
    function onSelect() {
        if (view.page == :home) { session.start(); view.page = :map; }
        else if (view.page == :map) { view.page = :menu; }
        else if (view.page == :pan) { view.panAxis = (view.panAxis + 1) % 2; }
        else if (view.page == :menu) {
            var n = view.selection; view.page = :map;
            if (n == 0) { session.recenter(); }
            else if (n == 1) { view.page = :pan; }
            else if (n == 2) {
                session.map.style = "day".equals(session.map.style) ? "night" : "day";
                session.map.generation++; session.map.wanted = true; session.save();
            } else if (n == 3) {
                session.map.size = session.map.size == 390 ? 195 : (session.map.size == 195 ? 256 : 390);
                session.map.generation++; session.map.wanted = true;
            } else if (n == 4) { view.page = :diagnostics; }
            else if (n == 5) { session.probeStorage(); view.page = :diagnostics; }
            else if (n == 6) { session.map.permanent = false; session.map.wanted = true; session.map.nextAttempt = 0; }
            else if (n == 7) { session.stop(); view.page = :home; }
        } else { view.page = :map; }
        return redraw();
    }
    function onNextPage() { return move(-1); }
    function onPreviousPage() { return move(1); }
    function move(delta) {
        if (view.page == :menu) { view.selection = (view.selection - delta + 8) % 8; }
        else if (view.page == :map) { session.map.changeZoom(delta); session.save(); }
        else if (view.page == :pan) {
            session.pan(view.panAxis == 1 ? delta : 0, view.panAxis == 0 ? delta : 0);
        }
        return redraw();
    }
    function onBack() {
        if (view.page == :home) { return false; }
        if (view.page == :map) { session.stop(); view.page = :home; }
        else if (view.page == :pan) { session.recenter(); view.page = :map; }
        else { view.page = :map; }
        return redraw();
    }
}
