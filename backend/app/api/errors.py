"""One error envelope for every response (docs/prd/12-api-contracts.md)."""

import logging
import uuid
from collections.abc import Awaitable, Callable
from typing import Any

from fastapi import FastAPI, Request, Response
from fastapi.encoders import jsonable_encoder
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.domain.errors import (
    Conflict,
    DomainError,
    InvalidInput,
    NotFound,
    PermissionDenied,
    Unauthenticated,
    Unavailable,
)

REQUEST_ID_HEADER = "X-Request-Id"


class ErrorBody(BaseModel):
    code: str
    message: str
    fields: dict[str, Any]
    request_id: str = Field(serialization_alias="requestId", validation_alias="requestId")


class ErrorEnvelope(BaseModel):
    """Documents the error body in OpenAPI so the generated client can read it."""

    error: ErrorBody


def error_responses(*statuses: int) -> dict[int | str, dict[str, Any]]:
    return {status: {"model": ErrorEnvelope, "description": "Error"} for status in statuses}


_STATUS: dict[type[DomainError], int] = {
    InvalidInput: 400,
    Unauthenticated: 401,
    PermissionDenied: 403,
    NotFound: 404,
    Conflict: 409,
    Unavailable: 503,
}

_HTTP_CODES = {
    400: "invalid_input",
    401: "unauthenticated",
    403: "permission_denied",
    404: "not_found",
    405: "invalid_input",
    503: "unavailable",
}


def _status_for(exc: DomainError) -> int:
    for cls in type(exc).__mro__:
        if cls in _STATUS:
            return _STATUS[cls]
    return 500


def _request_id(request: Request) -> str:
    return str(getattr(request.state, "request_id", ""))


def _envelope(
    request: Request,
    status: int,
    code: str,
    message: str,
    fields: dict[str, Any] | None = None,
    headers: dict[str, str] | None = None,
) -> JSONResponse:
    request_id = _request_id(request)
    response_headers = {REQUEST_ID_HEADER: request_id, **(headers or {})}
    body = {
        "error": {"code": code, "message": message, "fields": fields or {}, "requestId": request_id}
    }
    return JSONResponse(body, status_code=status, headers=response_headers)


def _without_default_422(app: FastAPI) -> Callable[[], dict[str, Any]]:
    """We answer validation failures with 400 invalid_input, so the stock 422 is a lie."""
    original = app.openapi

    def openapi() -> dict[str, Any]:
        if app.openapi_schema is None:
            schema = original()
            for path in schema.get("paths", {}).values():
                for operation in path.values():
                    operation.get("responses", {}).pop("422", None)
            for name in ("HTTPValidationError", "ValidationError"):
                schema.get("components", {}).get("schemas", {}).pop(name, None)
        return app.openapi_schema or {}

    return openapi


def install_error_handling(app: FastAPI) -> None:
    app.openapi = _without_default_422(app)  # type: ignore[method-assign]  # FastAPI's documented hook

    @app.middleware("http")
    async def request_id_middleware(
        request: Request, call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        request.state.request_id = uuid.uuid4().hex
        response = await call_next(request)
        response.headers[REQUEST_ID_HEADER] = request.state.request_id
        return response

    @app.exception_handler(DomainError)
    async def on_domain_error(request: Request, exc: Exception) -> JSONResponse:
        assert isinstance(exc, DomainError)  # noqa: S101 - narrows the handler's argument type
        headers = {"WWW-Authenticate": "Bearer"} if isinstance(exc, Unauthenticated) else None
        return _envelope(
            request, _status_for(exc), exc.code, exc.message, dict(exc.fields), headers
        )

    @app.exception_handler(RequestValidationError)
    async def on_validation_error(request: Request, exc: Exception) -> JSONResponse:
        assert isinstance(exc, RequestValidationError)  # noqa: S101
        fields = {
            ".".join(str(p) for p in err["loc"] if p != "body"): str(err["msg"])
            for err in exc.errors()
        }
        return _envelope(request, 400, "invalid_input", "Check the highlighted fields.", fields)

    @app.exception_handler(StarletteHTTPException)
    async def on_http_error(request: Request, exc: Exception) -> JSONResponse:
        assert isinstance(exc, StarletteHTTPException)  # noqa: S101
        code = _HTTP_CODES.get(exc.status_code, "internal")
        fields = jsonable_encoder(exc.detail) if isinstance(exc.detail, dict) else None
        message = "We could not complete that request."
        return _envelope(request, exc.status_code, code, message, fields)

    @app.exception_handler(Exception)
    async def on_unexpected(request: Request, exc: Exception) -> JSONResponse:
        # Stack goes to the log; the body stays generic.
        logging.getLogger("mechanica").error(
            "unhandled error", exc_info=exc, extra={"fields": {"request_id": _request_id(request)}}
        )
        return _envelope(request, 500, "internal", "Something went wrong. Try again.")
