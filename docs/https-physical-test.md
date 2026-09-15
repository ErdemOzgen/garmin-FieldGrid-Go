# Physical OpenFreeMap test through temporary HTTPS

Prepared 14 September 2026. **CLOSED — authorized experiment completed.**
The real location HTTPS test began at 20:58:42 UTC. Automatic shutdown completed
at 21:28:43 UTC (1,800.5 seconds including process cleanup). Tunnel/API processes
stopped, both local listening ports closed, and original .env/watch configuration
was restored byte for byte. No further public exposure is authorized by this test.

The previous installed build omitted the Mac only localhost origin. A new `fr165`
build with the temporary HTTPS origin has now been transferred and downloaded
back from the physical watch; all 127,276 bytes match. HTTPS preflight with a fixed
public Utrecht sample returned a real OpenFreeMap PNG and rejected an unauthorized
render request. The first physical run crashed in drawBitmap2 after successful
downloads. A native color fix was tested, installed and read back (128,012 B).
The user confirms real maps now display without crashing and a short locked iPhone
refresh with UP/DOWN zoom works. Continuous 30-minute background endurance remains
NOT RUN. The physical watch
retains this fixed test build, whose temporary origin has now expired. Offline GPS
continues to work; fresh online maps require a separately configured stable service.
See [sanitized evidence](evidence/physical-https.json).

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
   and explicitly selects START to open a map. DOWN remains network free GPS only.
5. Confirm streets/paths and OpenMapTiles/OpenStreetMap credits on the real watch.
   Collect only success/failure, image count, error code and memory; do not request
   the user's exact coordinates or publish raw location/screenshots.
6. Stop the tunnel/API by the time limit and restore local configuration. Keep
   offline GPS usable. The temporary map origin expires; this is not permanent hosting.

## Data and access

START in an online session sends the watch's map center coordinates to the Python
renderer through Garmin and Cloudflare. Garmin's converter also retrieves the
signed PNG, whose bounds reveal the viewed area. OpenFreeMap receives viewport
vector tile requests (the approximate viewed area), not the application's token.
No GPS history database is created. API access logs are disabled. Private tokens,
signed URLs, raw device XML, location bearing logs and personal screenshots stay
out of Git. Anonymous render calls are rejected; image grants last 120 seconds.

Only this single device service is exposed. Health/OpenAPI may be public; code,
local files and the filesystem are not served. Cloudflare Quick Tunnels are a
public, temporary origin, and the Mac must remain awake and online during the test.

## Completion boundary

This proves the physical map transfer only if the real watch displays the image.
It does not pass G0/G3, iPhone background/30-minute endurance, battery, or permanent
field availability. A stable HTTPS renderer is a separate deployment decision.

Authorization source: [AGENTS.md](../AGENTS.md), “No paid provider, public deployment,
store publishing or account changes without the user's authorization.”
