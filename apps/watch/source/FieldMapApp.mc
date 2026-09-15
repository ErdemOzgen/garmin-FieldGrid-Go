import Toybox.Application;
import Toybox.ActivityMonitor;
import Toybox.Sensor;
import Toybox.Position;
import Toybox.System;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;
import Toybox.Lang;

class FieldMapApp extends Application.AppBase {
    var session as FieldSession;
    function initialize() { AppBase.initialize(); session = new FieldSession(); }
    function getInitialView() {
        var view = new FieldView(session);
        return [view, new FieldDelegate(view, session)];
    }
    function onStop(state) { session.stop(); }
    function onInactive(state) { session.inactive(); }
    function onActive(state) { session.active(); }
}

// Ephemeral session only: no activity recorder, persistence writer or phone API.
class FieldSession {
    var gps as GpsState;
    var grid as GridState;
    var opened = false;
    var running = false;
    var subscribed = false;
    var ticker = null;
    var startedMs = null;
    var elapsed = 0;
    var peakMemory = 0;
    var updateCount = 0;
    var error = null;
    var lastResult = null;
    var motion as MotionState;
    var sensorSubscribed = false;

    function initialize() {
        gps = new GpsState(); grid = new GridState(); motion = new MotionState();
        // Upgrade cleanup touches only our three known obsolete keys, never activities.
        try {
            var keys = ["grid-preferences-v1", "preferences-v1", "g0-probe"];
            for (var i = 0; i < keys.size(); i++) {
                if (Application.Storage.getValue(keys[i]) != null) { Application.Storage.deleteValue(keys[i]); }
            }
        } catch (e) { error = "Old settings cleanup failed"; }
    }
    function start() {
        if (opened) { return false; }
        gps = new GpsState(); grid.center = null; grid.follow = true;
        elapsed = 0; updateCount = 0; lastResult = null; error = null;
        opened = true;
        return resume();
    }
    function enableGps() {
        if (!running || subscribed) { return; }
        try {
            Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
            subscribed = true; error = null;
        } catch (e) { error = "GPS unavailable - retry"; }
    }
    function disableGps() {
        if (subscribed) {
            Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
            subscribed = false;
        }
        gps.gap = true;
    }
    function startTicker() {
        if (ticker == null && running) {
            ticker = new Timer.Timer(); ticker.start(method(:tick), 1000, true);
        }
    }
    function stopTicker() { if (ticker != null) { ticker.stop(); ticker = null; } }
    function enableMotion() {
        if (!running || !motion.enabled || sensorSubscribed) { return; }
        motion.clear();
        try {
            Sensor.registerSensorDataListener(method(:onMotion), {
                :period => 1, :accelerometer => {:enabled => true, :sampleRate => 25}
            });
            sensorSubscribed = true;
        } catch (e) { motion.unavailable = true; }
        readSteps();
    }
    function disableMotion() {
        if (sensorSubscribed) {
            Sensor.unregisterSensorDataListener(); sensorSubscribed = false;
        }
        motion.clear(); gps.motionHint = null;
    }
    function toggleMotion() {
        disableMotion(); motion.enabled = !motion.enabled;
        if (motion.enabled && running && subscribed) { enableMotion(); }
    }
    function readSteps() {
        if (!running || !motion.enabled) { return; }
        try { motion.steps(ActivityMonitor.getInfo().steps, System.getTimer()); }
        catch (e) { motion.steps(null, System.getTimer()); }
    }
    function onMotion(data as Sensor.SensorData) as Void {
        if (!running || !sensorSubscribed) { return; }
        var a = data.accelerometerData;
        if (a == null) { motion.sample(null, null, null, System.getTimer()); return; }
        motion.sample(a.x, a.y, a.z, System.getTimer());
    }
    function inactive() {
        // Garmin restricts GPS while hidden; resume with a gap, never invent a path.
        disableMotion(); disableGps(); stopTicker();
    }
    function active() { if (running) { enableGps(); enableMotion(); startTicker(); } }
    function seconds() {
        return elapsed + (startedMs == null ? 0 : Geo.max(0, System.getTimer() - startedMs) / 1000);
    }
    function distance() { return gps.distance; }
    function speed() {
        if (!running || !gps.usable(System.getTimer()) || "REACQUIRE".equals(gps.filter.status)) { return null; }
        return gps.filter.moving ? gps.speed : 0;
    }
    function pause() {
        if (!running) { return; }
        elapsed = seconds(); startedMs = null; running = false;
        disableMotion(); disableGps(); stopTicker();
    }
    function resume() {
        if (!opened) { return false; }
        if (running) { return true; }
        running = true; startedMs = System.getTimer();
        enableGps(); enableMotion(); startTicker(); return true;
    }
    function stop() {
        running = false; opened = false; startedMs = null; elapsed = 0;
        disableMotion(); disableGps(); stopTicker();
        motion = new MotionState();
        gps = new GpsState(); grid.center = null; updateCount = 0;
        lastResult = "Session cleared";
    }
    function onPosition(info as Position.Info) as Void {
        if (!running || !subscribed) { return; }
        updateCount++;
        if (info.position == null || info.when == null) {
            gps.quality = Position.QUALITY_NOT_AVAILABLE; gps.gap = true; return;
        }
        var ll = info.position.toDegrees();
        gps.motionHint = motion.hint(System.getTimer());
        gps.accept(ll[0], ll[1], info.when.value(), info.accuracy, info.speed, Time.now().value(), System.getTimer());
        grid.track(gps.xy);
        // One timer owns repaint cadence; GPS callbacks only update bounded state.
    }
    function tick() as Void {
        if (!running) { return; }
        readSteps();
        peakMemory = Geo.max(peakMemory, System.getSystemStats().usedMemory);
        WatchUi.requestUpdate();
    }
}
