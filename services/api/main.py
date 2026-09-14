"""Small G0 service. OpenFreeMap rasters, no account or location database.

Loopback by default. An explicitly configured HTTPS base URL and one development
device token enable a private G0 field experiment. This is not G2 authentication.
"""

import hashlib
import hmac
import os
import secrets
import threading
import time
from collections import OrderedDict
from contextlib import asynccontextmanager
from dataclasses import dataclass
from urllib.parse import urlsplit

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse, Response
from starlette.exceptions import HTTPException

from services.api.models import ApiError, RenderRequest, RenderResponse
from services.api.openfreemap import OpenFreeMap, ProviderError
from services.api.renderer import render


@dataclass(frozen=True)
class Settings:
    base_url: str = "http://127.0.0.1:8765"
    device_token: str = ""
    signing_key: bytes = b""
    ttl: int = 120
    max_entries: int = 24
    requests_per_minute: int = 30
    provider: str = "synthetic"

    def __post_init__(self):
        parsed = urlsplit(self.base_url)
        local = parsed.hostname in {"127.0.0.1", "localhost", "::1"}
        if (
            parsed.scheme not in {"http", "https"}
            or not parsed.hostname
            or (not local and parsed.scheme != "https")
            or parsed.username
            or parsed.password
            or parsed.query
            or parsed.fragment
            or parsed.path not in {"", "/"}
        ):
            raise ValueError("base URL must be an HTTPS origin (HTTP allowed only on loopback)")
        if not local and len(self.device_token) < 32:
            raise ValueError("remote G0 service requires a random development device token")
        if self.ttl < 1 or self.max_entries < 1 or self.requests_per_minute < 1:
            raise ValueError("service limits must be positive")
        if self.provider not in {"synthetic", "openfreemap"}:
            raise ValueError("unsupported map provider")


def create_app(settings: Settings | None = None, clock=time.time, provider=None) -> FastAPI:
    settings = settings or Settings(
        base_url=os.getenv("FR165_PUBLIC_BASE_URL", "http://127.0.0.1:8765").rstrip("/"),
        device_token=os.getenv("FR165_DEV_TOKEN", ""),
        provider=os.getenv("FR165_MAP_PROVIDER", "openfreemap"),
    )
    signing_key = settings.signing_key or secrets.token_bytes(32)
    cache: OrderedDict[str, tuple[float, bytes]] = OrderedDict()
    lock = threading.Lock()
    render_lock = threading.Lock()
    provider = provider or (OpenFreeMap() if settings.provider == "openfreemap" else None)
    rate = {"start": clock(), "count": 0}

    @asynccontextmanager
    async def lifespan(_app):
        yield
        if provider is not None:
            provider.close()

    app = FastAPI(
        title="FieldMap raster service", version="0.1.0", docs_url="/docs", lifespan=lifespan
    )

    def error(status: int, code: str, retry: bool = False, after: int = 0):
        return JSONResponse(
            status_code=status,
            content=ApiError(
                code=code, retryable=retry, retryAfterSec=after, requestId=secrets.token_hex(6)
            ).model_dump(),
            headers={"Retry-After": str(after)} if after else {},
        )

    @app.exception_handler(RequestValidationError)
    async def invalid_request(_request, _exc):
        # Default validation errors echo inputs; those can contain coordinates.
        return error(422, "INVALID_REQUEST")

    @app.exception_handler(HTTPException)
    async def http_error(_request, exc):
        return error(exc.status_code, "REQUEST_REJECTED")

    @app.middleware("http")
    async def limits(request: Request, call_next):
        if request.method == "POST":
            body = bytearray()
            async for chunk in request.stream():
                if len(body) + len(chunk) > 2048:
                    return error(413, "REQUEST_TOO_LARGE")
                body.extend(chunk)
            request._body = bytes(body)
        response = await call_next(request)
        response.headers["Cache-Control"] = "no-store"
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Referrer-Policy"] = "no-referrer"
        return response

    @app.get("/health")
    def health():
        return {"status": "ok", "stage": "G0", "provider": settings.provider, "version": "0.1.0"}

    @app.post(
        "/v1/map-renders",
        response_model=RenderResponse,
        responses={401: {"model": ApiError}, 429: {"model": ApiError}},
    )
    def create_render(payload: RenderRequest, request: Request):
        expected = f"Bearer {settings.device_token}"
        if settings.device_token and not hmac.compare_digest(
            request.headers.get("Authorization", "").encode(), expected.encode()
        ):
            return error(401, "DEVICE_TOKEN_REQUIRED")
        now = clock()
        with lock:
            if now - rate["start"] >= 60:
                rate.update(start=now, count=0)
            if rate["count"] >= settings.requests_per_minute:
                return error(429, "RATE_LIMITED", True, max(1, int(60 - now + rate["start"])))
            rate["count"] += 1
            for key in list(cache):
                if cache[key][0] <= now:
                    del cache[key]
        # Never queue unbounded rendering work or hold the image-cache lock over network I/O.
        if not render_lock.acquire(blocking=False):
            return error(503, "RENDER_BUSY", True, 1)
        try:
            if provider is None:
                data, box = render(payload)
                version, attribution = "synthetic-grid-v1", "SYNTHETIC TEST MAP"
            else:
                data, box, version, attribution = provider.render(payload)
        except ProviderError:
            return error(503, "MAP_PROVIDER_UNAVAILABLE", True, 5)
        finally:
            render_lock.release()
        with lock:
            render_id = secrets.token_hex(16)
            expires = int(clock()) + settings.ttl
            cache[render_id] = (expires, data)
            while len(cache) > settings.max_entries:
                cache.popitem(last=False)
        signature = hmac.new(
            signing_key, f"{render_id}:{expires}".encode(), hashlib.sha256
        ).hexdigest()
        return RenderResponse(
            requestGeneration=payload.requestGeneration,
            renderId=render_id,
            bounds3857=box,
            imageWidth=payload.imageSize,
            imageHeight=payload.imageSize,
            zoom=payload.zoom,
            styleVersion=f"{payload.style}-v1",
            mapDataVersion=version,
            attribution=attribution,
            expiresAt=expires,
            imageUrl=f"{settings.base_url}/v1/images/{render_id}?expires={expires}&sig={signature}",
        )

    @app.get("/v1/images/{render_id}", responses={200: {"content": {"image/png": {}}}})
    def get_image(render_id: str, expires: int, sig: str):
        if len(render_id) != 32 or len(sig) != 64:
            return error(403, "INVALID_IMAGE_GRANT")
        expected = hmac.new(
            signing_key, f"{render_id}:{expires}".encode(), hashlib.sha256
        ).hexdigest()
        if expires <= clock() or not hmac.compare_digest(expected.encode(), sig.encode()):
            return error(403, "INVALID_IMAGE_GRANT")
        with lock:
            entry = cache.get(render_id)
            if entry is None or entry[0] <= clock():
                return error(410, "RENDER_EXPIRED", True)
            data = entry[1]
        return Response(data, media_type="image/png", headers={"X-Render-Id": render_id})

    return app


app = create_app()
