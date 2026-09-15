# Historical temporary HTTPS simulator experiment

This plan belongs to the former raster application. FieldGrid needs no server or
tunnel. Normal build/run commands open no public endpoint. Any new tunnel requires
fresh, explicit authorization; this document is not permission to publish.

## Access boundary

The former makeWebRequest could retrieve localhost metadata, but Garmin's external
image converter needed a reachable PNG URL. SDK 9.2.0/fr165 returned HTTP 200 with
null for localhost images; the app reported -903 while GPS continued. The
[Garmin explanation](https://forums.garmin.com/developer/connect-iq/f/discussion/256721/connect-mobile-4-40-makeimagerequest-localhost-error/1226813)
describes that path.

The proposed official cloudflared Quick Tunnel forwarded only
`http://127.0.0.1:8765` through a random `*.trycloudflare.com` HTTPS origin. The API
served no source files. Rendering needed a random development token; PNG access
used a 120 second HMAC grant. Health and schema were public. Cloudflare saw network
traffic; Garmin saw synthetic PNGs and temporary image URLs.

Only labeled synthetic maps and coordinates were authorized. Maximum duration was
30 minutes, followed by shutdown and configuration restoration. No account, DNS,
paid service or persistent system installation was created. Tools stayed in `/tmp`;
keys and tunnel logs remained outside Git.

## Original sequence

1. Obtain approval for the concrete temporary exposure.
2. Back up `.env` and `.local/watch.json` privately with permissions 0600.
3. Start `cloudflared tunnel --url http://127.0.0.1:8765 --no-autoupdate`.
4. Update both private origins and restart the former service/simulator.
5. Test synthetic GPS, 195/256/390 px, two themes, three zooms and outage recovery.
6. Record sanitized results, stop tunnel/API and restore local configuration.
7. Rebuild the physical binary without local HTTP/test credentials and refresh the package.

Quick Tunnels were development exposure, not production hosting. The historical
[Cloudflare documentation](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/)
was consulted for its public temporary origin and lack of SLA.

## Recorded outcome

The user authorized the synthetic test on 14 September 2026. It ran from
18:49:58 to 19:12:03 UTC, approximately 1324.5 seconds. The tunnel exited with code 0;
the API stopped; both local files were restored with permissions 0600; simulator
HTTPS requirements were reenabled. No permanent service/account/DNS was created.
See the [historical record](evidence/previous-synthetic-simulator.json).

A subsequent real OpenFreeMap test required separate authorization. Its proposal
used only fixed Utrecht samples and a generated GPX path for at most 30 minutes.
Cloudflare carried renderer traffic, Garmin converted PNGs, and OpenFreeMap received
viewport tile requests. No personal GPS, paid resource or persistent publication was
part of that proposal. Previous approval did not authorize another run.
