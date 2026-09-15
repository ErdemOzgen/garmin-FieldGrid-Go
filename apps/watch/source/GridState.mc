import Toybox.Lang;

class GridState {
    var center as Array or Null = null;
    var zoom = 17;
    var night = false;
    var follow = true;
    const MIN_ZOOM = 10;
    const MAX_ZOOM = 19;
    function initialize() {}
    function changeZoom(delta) { zoom = Geo.max(MIN_ZOOM, Geo.min(MAX_ZOOM, zoom + delta)); }
    function recenter(xy as Array or Null) {
        follow = true;
        if (xy != null) { center = [xy[0], xy[1]]; }
    }
    function track(xy as Array or Null) {
        if (xy == null || !follow) { return; }
        if (center == null || Geo.abs(Geo.wrapX(xy[0] - center[0])) > Geo.resolution(zoom) * 65 ||
            Geo.abs(xy[1] - center[1]) > Geo.resolution(zoom) * 65) { recenter(xy); }
    }
    function pan(dx, dy) {
        if (center == null) { return; }
        follow = false;
        center = [Geo.wrapX(center[0] + dx * Geo.resolution(zoom)),
            Geo.max(-Geo.WORLD / 2, Geo.min(Geo.WORLD / 2, center[1] + dy * Geo.resolution(zoom)))];
    }
}
