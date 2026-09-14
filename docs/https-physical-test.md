# Physical OpenFreeMap test through temporary HTTPS

Prepared 14 September 2026. **NOT STARTED — awaiting explicit authorization.**
The installed app opens on the actual Forerunner 165, but its build intentionally
omits the Mac-only localhost origin. This is why it cannot fetch real street maps.
The previous authorization covered only the completed synthetic simulator test;
it does not cover a new public endpoint carrying real watch location.

## Concrete proposed action

1. Back up `.env` and `.local/watch.json` into a private, ignored directory.
2. Start the existing loopback Python renderer (`FR165_MAP_PROVIDER=openfreemap`)
   and the verified Cloudflare Quick Tunnel binary in `/tmp`. Limit public access
   to 30 minutes with automatic process termination. No account, DNS, paid resource,
   global package or permanent service is created.
3. Put the temporary HTTPS origin and the existing private device token in the
   local configuration, compile `make build-watch` for `fr165`, and replace only
   our FieldMap application on the watch. Retain the prior PRG privately for rollback.
4. User disconnects USB, keeps the watch paired with Garmin Connect on the iPhone,
   and explicitly selects START to open a map. DOWN remains network-free GPS only.
5. Confirm streets/paths and OpenMapTiles/OpenStreetMap credits on the real watch.
   Collect only success/failure, image count, error code and memory; do not request
   the user's exact coordinates or publish raw location/screenshots.
6. Stop the tunnel/API by the time limit and restore local configuration. Keep
   offline GPS usable. The temporary map origin expires; this is not permanent hosting.

## Data and access

START in an online session sends the watch's map-center coordinates to the Python
renderer through Garmin and Cloudflare. Garmin's converter also retrieves the
signed PNG, whose bounds reveal the viewed area. OpenFreeMap receives viewport
vector-tile requests (the approximate viewed area), not the application's token.
No GPS history database is created. API access logs are disabled. Private tokens,
signed URLs, raw device XML, location-bearing logs and personal screenshots stay
out of Git. Anonymous render calls are rejected; image grants last 120 seconds.

Only this single-device service is exposed. Health/OpenAPI may be public; code,
local files and the filesystem are not served. Cloudflare Quick Tunnels are a
public, temporary origin, and the Mac must remain awake and online during the test.

## Completion boundary

This proves the physical map transfer only if the real watch displays the image.
It does not pass G0/G3, iPhone background/30-minute endurance, battery, or permanent
field availability. A stable HTTPS renderer is a separate deployment decision.

Authorization source: [AGENTS.md](../AGENTS.md), “No paid provider, public deployment,
store publishing or account changes without the user's authorization.”
