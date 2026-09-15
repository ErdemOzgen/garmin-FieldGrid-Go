# ADR 002 — Separate GPS, camera and network state

Historical raster decision. Current grid behavior is defined by ADR 006 and ADR 007.

`GpsState` checked quality, UTC timestamps and monotonic reception age. Invalid,
missing and unsupported coordinates were rejected without a default zero location.
Last Known or Poor GPS was not a fresh fix. The initial trace held 180 points,
added points after movement of 3 m or elapsed time of 5 s, and split at gaps.
Older UTC fixes and monotonic counter wrap were not mistaken for fresh data.
The later grid filter removes timer driven stationary points.

`MapState` owned camera, zoom, style and generation. There was one logical job;
new camera changes replaced the desired view instead of creating a queue.
`MapJob` downloaded metadata and image in sequence. Every callback checked the
session, job identity and generation. Image identity, transform and dimensions
had to be valid before activation.

A raster retained its own geographic bounds during pan and zoom. Old imagery was
never relabeled as a new area. The local G0 grid image was explicitly synthetic.
One incoming bitmap could briefly overlap the active bitmap for atomic replacement;
physical graphics cost required field measurement.

Request starts were at least 5 s apart. Timeout was 25 s; retry delays were
2/4/8/16/30 s plus 0–500 ms jitter. A 429 response could supply `retryAfterSec`.
401/403/413/422 and invalid schemas required explicit Retry service, not movement.

The API bounded request bodies to 2 KiB, profiles to three zooms, three sizes and
two themes, and renders to 30 per minute. The G0 development token was not production
pairing, refresh or revocation. Image access used a separate HMAC bound to a render
ID and 120 s expiry. The device token never appeared in an image URL.

At most 24 rasters stayed in RAM; expired items were removed during new renders.
Restart invalidated URLs and cache. Only one API process was supported because
multiple workers would not share signing/cache state. Shared storage required a
later measured need.
