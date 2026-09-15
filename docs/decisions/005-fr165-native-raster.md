# ADR 005 — Native raster before FR165 transforms

14 September 2026. Supersedes ADR 004's on watch raster format and peak resource
description; the provider PNG, network palette and geographic protocol are unchanged.

The physical watch downloaded real OpenFreeMap images but displayed the IQ error
screen. Its CIQ log identifies an unhandled exception in `FieldView.onUpdate`,
line 127 of the previous source, at `dc.drawBitmap2(..., :transform => ...)`.
The log reports firmware 29.05 and runtime Connect IQ 6.0.2. The exception's
subtype is not included. Garmin has acknowledged a matching FR165 transform
restriction requiring native color sources instead of palette backed resources.
Thus the format restriction is the working diagnosis; physical retest is required.

The download remains a bounded 16-color image. After dimension validation, it is
drawn once into a native 16-bit BufferedBitmap with no custom palette. Only that
native buffer and its matching metadata are committed. The downloaded resource
is released when the callback returns. A same size raster uses plain drawBitmap;
zoom scaling uses drawBitmap2 on the native buffer. Scale arguments are Float,
as required by the installed AffineTransform API.

Conversion errors retain the old map and use bounded retry (-904). Drawing errors
drop the failed bitmap and metadata together, retain GPS and any existing network
job, and expose diagnostic -905 instead of terminating the app.

There is one active native raster, at most one incoming native raster, and the
incoming paletted download during conversion. Native pixel storage is at most
390 × 390 × 2 = 304,200 bytes per raster, excluding graphics allocator overhead.
This is a constant graphics pool cost, not a growing map cache or persistent file.
The SDK profile reports a 2 MiB graphics pool; physical total pool usage is not
measured and must not be confused with application heap.

The new regression passes an actual resource through onImage, draws scaled views,
and verifies that invalid dimensions retain the previous raster/GPS subscription.
The stress test now includes palette to native conversion for 160 replacements
over 40 sessions. All 22 tests pass on fr165. Post stop application heap is 46,656 B;
overlap peak 65,560 B. A final log call allocates another 112 B. These are simulator
heap samples, not physical/native pool/battery acceptance.

Sources:
- Installed SDK 9.2.0: Graphics.createBufferedBitmap, Dc.drawBitmap/drawBitmap2,
  BitmapReference.getWidth/getHeight and AffineTransform.scale.
- [Garmin's acknowledged FR165 report and staff workaround](https://forums.garmin.com/developer/connect-iq/i/bug-reports/call-to-drawbitmap2-causes-exception-on-fr165-and-fr165m).
- [Graphics pool documentation](https://developer.garmin.com/connect-iq/core-topics/graphics/).

The original network attempt is FAIL for physical map display. After installing
the fix, the user confirmed that the map appears without crashing. This recovery
is PASS by user report, supported by successful new metadata/PNG requests. It
does not establish endurance, native graphics memory, battery or full G0/G3 acceptance.
