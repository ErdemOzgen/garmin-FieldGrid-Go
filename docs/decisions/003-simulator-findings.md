# ADR 003 — Simulator transfer and storage findings

14 September 2026. Historical local findings, not physical G0 acceptance.

- Decimal coordinates in a CIQ JSON dictionary caused a 3.609287 m boundary error.
  `Geo.coordinateText` sent eight decimal places as text. The API accepted fixed
  decimal text or JSON numbers and rejected NaN, Infinity, booleans, exponent text
  and invalid ranges. The 2 m bound check was preserved. Later HTTPS rasters passed;
  both sides received precision regression tests.
- Garmin could not fetch a localhost PNG: HTTP 200 with null image became app error
  -903 while GPS continued. An explicitly authorized temporary Cloudflare HTTPS
  tunnel used only synthetic maps and coordinates. It closed after about 22 minutes
  at 19:12:03 UTC, and local settings were restored. The [Garmin explanation](https://forums.garmin.com/developer/connect-iq/f/discussion/256721/connect-mobile-4-40-makeimagerequest-localhost-error/1226813)
  documents the external image conversion path.
- The SDK UI blocked while waiting for macOS Keychain. The user completed the prompt;
  no password was read or stored.
- Old `Application.Properties` could override new build defaults. Raster configuration
  moved to ignored private build resources, including matching language resources.
  An offline simulator binary used no network. Current FieldGrid removes these
  private resources entirely.
- A large `Storage.setValue` experiment caused an uncaught OOM. Its exact input size
  was not measured; a 32 KB capacity pass was not claimed. Only a 1024 character
  write/read/compare/delete probe remained. Large storage, bitmap and reboot tests
  stayed NOT RUN. Current FieldGrid removes the probe and performs no new writes.
- The original Turkish BACK label clipped on the round display. It was shortened,
  long menu items used a smaller font, and theme changes preserved label contrast
  over retained rasters. Successful images were counted separately from attempts;
  dimensions were not shown as loaded before an image existed.

Interactive runs were allowed beyond 90 s, with at most three initial connection
attempts. Automated tests kept their timeout and could not reuse an old PASS result
after failure. No system Python or shell settings were modified.

The final English BACK hint was 171 px against a 168 px safe width. The shorter
BACK to map label measured 154 px and passed both language checks. That text change
was after the network test, so evidence keeps separate source identities.
