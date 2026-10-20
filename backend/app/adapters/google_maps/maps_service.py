"""Google Directions/Geocode over HTTPS. Bound only when a key is present."""

from __future__ import annotations

import asyncio
import json
from typing import Any
from urllib.error import URLError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from app.domain.errors import NotFound, Unavailable
from app.domain.maps import GeoPoint, RouteSummary

_GEOCODE = "https://maps.googleapis.com/maps/api/geocode/json"
_DIRECTIONS = "https://maps.googleapis.com/maps/api/directions/json"


class GoogleMapsService:
    def __init__(self, api_key: str) -> None:
        self._key = api_key

    async def geocode(self, address: str) -> GeoPoint:
        payload = await self._get(_GEOCODE, {"address": address, "key": self._key})
        results = payload.get("results") or []
        if not results:
            raise NotFound("We could not find that address.")
        loc = results[0]["geometry"]["location"]
        return GeoPoint(lat=float(loc["lat"]), lng=float(loc["lng"]))

    async def reverse_geocode(self, lat: float, lng: float) -> str:
        payload = await self._get(_GEOCODE, {"latlng": f"{lat},{lng}", "key": self._key})
        results = payload.get("results") or []
        if not results:
            raise NotFound("We could not find that address.")
        return str(results[0].get("formatted_address") or "Unknown")

    async def route(
        self, origin_lat: float, origin_lng: float, dest_lat: float, dest_lng: float
    ) -> RouteSummary:
        payload = await self._get(
            _DIRECTIONS,
            {
                "origin": f"{origin_lat},{origin_lng}",
                "destination": f"{dest_lat},{dest_lng}",
                "key": self._key,
            },
        )
        routes = payload.get("routes") or []
        if not routes:
            raise NotFound("We could not find a route.")
        leg = routes[0]["legs"][0]
        polyline = routes[0].get("overview_polyline", {}).get("points", "")
        return RouteSummary(
            distance_m=int(leg["distance"]["value"]),
            duration_s=int(leg["duration"]["value"]),
            encoded_polyline=str(polyline),
        )

    async def _get(self, url: str, params: dict[str, str]) -> dict[str, Any]:
        try:
            raw = await asyncio.to_thread(_fetch, f"{url}?{urlencode(params)}")
        except (URLError, TimeoutError, OSError) as exc:
            raise Unavailable("Maps is unavailable. Try again.") from exc
        status = raw.get("status")
        if status in {"ZERO_RESULTS", "NOT_FOUND"}:
            raise NotFound("We could not find that.")
        if status not in {"OK"}:
            raise Unavailable("Maps is unavailable. Try again.")
        return raw


def _fetch(url: str) -> dict[str, Any]:
    if not url.startswith("https://"):
        raise Unavailable("Maps is unavailable. Try again.")
    request = Request(url, method="GET")  # noqa: S310 - Google Maps HTTPS only
    with urlopen(request, timeout=10) as response:  # noqa: S310
        payload: dict[str, Any] = json.loads(response.read().decode("utf-8"))
        return payload
