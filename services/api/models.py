import re
from typing import Annotated, Literal

from pydantic import BaseModel, BeforeValidator, ConfigDict, Field

from services.api.geo import MAX_LAT


def decimal_coordinate(value):
    # CIQ's JSON number conversion loses coordinate precision. The watch sends
    # fixed decimal strings; numeric JSON remains supported for API clients.
    if isinstance(value, str):
        if not re.fullmatch(r"-?(?:0|[1-9]\d*)(?:\.\d{1,8})?", value):
            raise ValueError("invalid decimal coordinate")
    elif type(value) not in (int, float):
        raise ValueError("coordinate must be a number or fixed decimal string")
    return value


Coordinate = Annotated[
    float, BeforeValidator(decimal_coordinate, json_schema_input_type=float | str)
]


class RenderRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", allow_inf_nan=False)
    schemaVersion: Literal[1]
    requestGeneration: int = Field(ge=0, le=2_147_483_647)
    latDeg: Coordinate = Field(ge=-MAX_LAT, le=MAX_LAT)
    lonDeg: Coordinate = Field(ge=-180, le=180)
    zoom: Literal[14, 15, 16] = 15
    imageSize: Literal[195, 256, 390] = 390
    style: Literal["day", "night"] = "day"


class RenderResponse(BaseModel):
    schemaVersion: Literal[1] = 1
    requestGeneration: int
    renderId: str
    projection: Literal["EPSG:3857"] = "EPSG:3857"
    bounds3857: list[float] = Field(min_length=4, max_length=4)
    imageWidth: int
    imageHeight: int
    zoom: int
    styleVersion: str
    mapDataVersion: str = "synthetic-grid-v1"
    imageUrl: str
    expiresAt: int
    attribution: str = "SYNTHETIC TEST MAP"


class ApiError(BaseModel):
    code: str
    retryable: bool
    retryAfterSec: int = 0
    requestId: str
