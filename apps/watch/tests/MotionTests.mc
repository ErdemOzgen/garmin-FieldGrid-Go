import Toybox.Test;
import Toybox.Math;
import Toybox.System;

(:test)
module SyntheticMotion {
    function wrist(m, second, kind) {
        var x = new [25]; var y = new [25]; var z = new [25];
        for (var i = 0; i < 25; i++) {
            var t = second + i / 25.0;
            var angle = 0.15 * Math.sin(2 * Geo.PI * 0.3 * t);
            x[i] = kind == :rotation ? 1000 * Math.sin(angle) : 0;
            y[i] = 0;
            z[i] = kind == :rotation ? 1000 * Math.cos(angle) :
                (kind == :pulse ? 1000 + (second % 4 == 0 && i >= 8 && i < 12 ? 160 : 0) :
                 1000 + 35 * Math.sin(2 * Geo.PI * 2 * t));
        }
        m.sample(x, y, z, second * 1000);
    }
    function batch(m, second, walking) {
        var x = new [25]; var y = new [25]; var z = new [25];
        for (var i = 0; i < 25; i++) {
            var phase = 2 * Geo.PI * 1.6 * (second + i / 25.0);
            x[i] = walking ? 90 * Math.sin(phase) : (i % 3) - 1;
            y[i] = 0;
            z[i] = 1000 + (walking ? 140 * Math.cos(phase) : (i % 5) - 2);
        }
        m.sample(x, y, z, second * 1000);
    }
    function gait(m, second, cadence, amplitude) {
        var x = new [25]; var y = new [25]; var z = new [25];
        for (var i = 0; i < 25; i++) {
            var t = second + i / 25.0;
            var magnitude = 1000 + amplitude * Math.sin(2 * Geo.PI * cadence * t);
            var angle = 0.2 * Math.sin(2 * Geo.PI * 0.4 * t);
            x[i] = magnitude * Math.sin(angle); y[i] = 0; z[i] = magnitude * Math.cos(angle);
        }
        m.sample(x, y, z, second * 1000);
    }
}

(:test)
function smallWristMotionCannotReleaseStationaryGps(logger) {
    var kinds = [:rotation, :pulse, :vibration];
    for (var kind = 0; kind < kinds.size(); kind++) {
        var m = new MotionState(); var g = new GpsState();
        for (var warm = 0; warm < 10; warm++) { SyntheticMotion.batch(m, warm, false); }
        for (var i = 10; i < 610; i++) {
            SyntheticMotion.wrist(m, i, kinds[kind]); g.motionHint = m.hint(i * 1000);
            var phase = (i - 10) % 80;
            Synthetic.fix(g, (phase <= 40 ? phase : 80 - phase) * 0.275, i, 1.0);
        }
        Test.assert(g.count == 1 && g.distance == 0 && !g.filter.moving);
    }
    logger.debug("SYNTHETIC: 11 m GPS drift with rotation, isolated arm pulses and small vibrations stays held");
    return true;
}

(:test)
function isolatedStepCounterNoiseCannotReleaseHold(logger) {
    var m = new MotionState(); var g = new GpsState(); var steps = 5000;
    m.steps(steps, 0);
    for (var i = 0; i < 300; i++) {
        SyntheticMotion.batch(m, i, false);
        if (i > 0 && i % 20 == 0) { steps++; }
        m.steps(steps, i * 1000); g.motionHint = m.hint(i * 1000);
        Synthetic.fix(g, (i % 40) * 0.275, i, 0.8);
    }
    Test.assert(g.count == 1 && g.distance == 0);
    return true;
}

(:test)
function cadenceAssistancePreservesSlowWalkAndRun(logger) {
    var cadences = [0.6, 1.1, 1.6, 2.8]; var speeds = [0.35, 0.65, 1.4, 3.2];
    for (var n = 0; n < cadences.size(); n++) {
        var m = new MotionState(); var g = new GpsState();
        for (var i = 0; i <= 120; i++) {
            SyntheticMotion.gait(m, i, cadences[n], 90); g.motionHint = m.hint(i * 1000);
            Synthetic.fix(g, i * speeds[n], i, speeds[n]);
        }
        Test.assert(m.hint(120000) == true && g.filter.moving);
        Test.assert(g.distance > 120 * speeds[n] * 0.85 && g.distance < 120 * speeds[n] * 1.02);
        for (var j = 121; j < 128; j++) { SyntheticMotion.wrist(m, j, :rotation); }
        Test.assert(m.hint(127000) == false);
    }
    return true;
}

(:test)
function fastVibrationIsNotWalking(logger) {
    var m = new MotionState(); var g = new GpsState();
    for (var i = 0; i < 600; i++) {
        SyntheticMotion.gait(m, i, 4.0, 120); g.motionHint = m.hint(i * 1000);
        Synthetic.fix(g, (i % 40) * 0.275, i, 1.0);
    }
    Test.assert(m.hint(599000) == false && g.distance == 0 && g.count == 1);
    return true;
}

(:test)
function movementEvidenceDoesNotInventGpsDistance(logger) {
    var m = new MotionState(); var g = new GpsState();
    for (var i = 0; i < 120; i++) {
        SyntheticMotion.gait(m, i, 1.6, 120); g.motionHint = m.hint(i * 1000);
        Synthetic.fix(g, 0, i, 0.0);
    }
    Test.assert(m.hint(119000) == true && g.count == 1 && g.distance == 0);
    m.sample(null, null, null, 120000); Test.assert(m.hint(120000) == null);
    return true;
}

(:test)
function accelerometerStationarityRejectsMisleadingGpsSpeed(logger) {
    var m = new MotionState(); var g = new GpsState();
    for (var warm = 0; warm < 4; warm++) { SyntheticMotion.batch(m, warm, false); }
    Test.assert(m.hint(3000) == false);
    for (var i = 4; i < 604; i++) {
        SyntheticMotion.batch(m, i, false); g.motionHint = m.hint(i * 1000);
        Synthetic.fix(g, ((i - 4) % 200) * 0.17, i, 1.4);
    }
    Test.assert(g.count == 1 && g.distance == 0 && !g.filter.moving);
    Test.assert(m.hint(606001) == null);
    // A stale sensor must not permanently lock GPS based movement.
    for (var j = 607; j < 667; j++) {
        g.motionHint = m.hint(j * 1000); Synthetic.fix(g, 34 + (j - 607) * 1.4, j, 1.4);
    }
    Test.assert(g.filter.moving && g.distance > 70);
    logger.debug("SYNTHETIC: fresh still acceleration rejects 34 m drift even with GPS speed 1.4 m/s; stale sensor falls back");
    return true;
}

(:test)
function motionAssistedSlowWalkAndStop(logger) {
    var m = new MotionState(); var g = new GpsState();
    for (var i = 0; i <= 120; i++) {
        SyntheticMotion.batch(m, i, true); g.motionHint = m.hint(i * 1000);
        Synthetic.fix(g, i * 0.35, i, 0.35);
    }
    Test.assert(g.distance > 35 && g.distance < 43 && g.filter.moving);
    for (var j = 121; j < 130; j++) {
        SyntheticMotion.batch(m, j, false); g.motionHint = m.hint(j * 1000); Synthetic.fix(g, 42, j, 0.0);
    }
    var distance = g.distance;
    for (var k = 130; k < 330; k++) {
        SyntheticMotion.batch(m, k, false); g.motionHint = m.hint(k * 1000);
        Synthetic.fix(g, 42 + (k - 130) * 0.17, k, 0.8);
    }
    Test.assert(g.distance == distance && !g.filter.moving);
    return true;
}

(:test)
function stepEvidenceExpiresAndHandlesMidnight(logger) {
    var m = new MotionState();
    for (var i = 0; i <= 20; i++) { SyntheticMotion.batch(m, i, false); }
    m.steps(4000, 20000); Test.assert(m.hint(20000) == false);
    m.steps(4001, 20000); Test.assert(m.hint(20000) == false);
    SyntheticMotion.batch(m, 21, false); m.steps(4002, 21000); Test.assert(m.hint(21000) == false);
    SyntheticMotion.batch(m, 22, false); m.steps(4003, 22000); Test.assert(m.hint(22000) == true);
    for (var j = 23; j <= 26; j++) { SyntheticMotion.batch(m, j, false); m.steps(4003, j * 1000); }
    Test.assert(m.hint(26000) == true);
    SyntheticMotion.batch(m, 27, false); Test.assert(m.hint(27000) == false);
    m.steps(4006, 27000); Test.assert(m.hint(27000) == true);
    m.steps(0, 27001); Test.assert(m.hint(27001) == false);
    m.steps(null, 27002); m.steps(5, 27003); Test.assert(m.hint(27003) == false);
    m.steps(8, 27004); Test.assert(m.hint(27004) == true);
    m.enabled = false; Test.assert(m.hint(27004) == null);
    m.clear(); Test.assert(m.previousSteps == null && m.sampledMs == null && m.stepMs == null);
    return true;
}

(:test)
function invalidAndInterruptedAccelerationIsUnknown(logger) {
    var m = new MotionState();
    for (var i = 0; i < 4; i++) { SyntheticMotion.batch(m, i, false); }
    Test.assert(m.hint(3000) == false);
    m.sample([0,0,0,0,0], [0,0,0,0,0], [0,0,0,0,0], 4000);
    Test.assert(m.hint(4000) == null);
    m.sample(null, null, null, 5000); Test.assert(m.hint(5000) == null);
    m.sample([1], [1,2], [1000], 6000); Test.assert(m.hint(6000) == null);
    m.sample([1,1,1,1,1], [1,1,1,1,1], [1000,1000,null,1000,1000], 7000);
    Test.assert(m.hint(7000) == null);
    SyntheticMotion.batch(m, 10, false); Test.assert(m.hint(10000) == false && "VERIFY".equals(m.label(10000)));
    SyntheticMotion.batch(m, 20, false); Test.assert(m.hint(20000) == false && "VERIFY".equals(m.label(20000)));
    m.clear(); Test.assert(m.hint(20000) == null);
    return true;
}

(:test)
function motionSensorLifecycleIsBoundedAndOptional(logger) {
    var s = new FieldSession(); var v = new FieldView(s); var d = new FieldDelegate(v, s);
    Test.assert(!s.sensorSubscribed && s.motion.enabled);
    var warmed = 0; var peak = 0;
    for (var run = 0; run < 20; run++) {
        Test.assert(s.start() && s.sensorSubscribed);
        s.enableMotion(); Test.assert(s.sensorSubscribed);
        for (var i = 0; i < 600; i++) { SyntheticMotion.batch(s.motion, i, i < 300); }
        s.pause(); Test.assert(!s.sensorSubscribed && s.motion.sampledMs == null && s.motion.previousSteps == null);
        s.resume(); Test.assert(s.sensorSubscribed);
        s.inactive(); Test.assert(!s.sensorSubscribed); s.active(); Test.assert(s.sensorSubscribed);
        v.page = :diagnostics; d.onSelect(); Test.assert(!s.motion.enabled && !s.sensorSubscribed && s.running);
        d.onSelect(); Test.assert(s.motion.enabled && s.sensorSubscribed);
        s.stop(); Test.assert(!s.sensorSubscribed && s.motion.sampledMs == null && s.gps.motionHint == null);
        var memory = System.getSystemStats().usedMemory; peak = Geo.max(peak, memory);
        if (run == 5) { warmed = memory; }
        if (run > 5) { Test.assert(memory <= warmed + 512); }
    }
    logger.debug("SYNTHETIC 12000 acceleration batches / 300000 samples, 20 sensor lifecycle loops; peak post-stop heap: " + peak);
    return true;
}
