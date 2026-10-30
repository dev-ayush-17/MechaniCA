"""One-phone dry-run: customer create + mechanic accept and complete via the API."""

from __future__ import annotations

import json
import time
import uuid
import urllib.error
import urllib.request

BASE = "http://127.0.0.1:8000"
CUST = "fake:fake_918853981222:+918853981222"
MECH = "fake:fake_919800000001:+919800000001"
VEH = "adab3a4f-792c-46d1-828a-e14eb30cf3b2"
ADDR = "25ea84fd-1283-434a-8e08-b3f01b9eb444"


def call(method: str, path: str, token: str, body: dict | None = None, extra: dict | None = None):
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    if extra:
        headers.update(extra)
    data = None if body is None else json.dumps(body).encode()
    req = urllib.request.Request(BASE + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            raw = response.read().decode() or "{}"
            return response.status, json.loads(raw) if raw.strip() else {}
    except urllib.error.HTTPError as exc:
        raw = exc.read().decode()
        try:
            payload = json.loads(raw)
        except json.JSONDecodeError:
            payload = {"raw": raw}
        return exc.code, payload


def main() -> None:
    status, mech = call("POST", "/v1/mechanic/availability", MECH, {"online": True})
    print("online", status, mech.get("online"), mech.get("displayName"))
    print("heartbeat", call("POST", "/v1/mechanic/heartbeat", MECH)[0])
    key = str(uuid.uuid4())
    status, booking = call(
        "POST",
        "/v1/bookings",
        CUST,
        {
            "vehicleId": VEH,
            "serviceCode": "oil_change",
            "addressId": ADDR,
            "mode": "instant",
            "urgency": "normal",
            "paymentMethod": "upi",
            "couponCode": "",
        },
        extra={"Idempotency-Key": key},
    )
    print("create", status, booking.get("id"), booking.get("status"), booking.get("error"))
    if status >= 400:
        raise SystemExit(1)
    booking_id = booking["id"]
    call("POST", "/v1/mechanic/heartbeat", MECH)
    offer: dict = {}
    for attempt in range(10):
        time.sleep(1)
        status, offer = call("GET", "/v1/offers/open", MECH)
        print("offer", attempt, status, offer.get("id"), offer.get("serviceName"))
        if status == 200 and offer.get("id"):
            break
        call("POST", "/v1/mechanic/heartbeat", MECH)
    if not offer.get("id"):
        _, booked = call("GET", f"/v1/bookings/{booking_id}", CUST)
        print("miss", booked.get("status"), booked.get("failureReason"))
        raise SystemExit(2)
    status, accepted = call("POST", f"/v1/offers/{offer['id']}/accept", MECH)
    print("accept", status, accepted)
    version = accepted.get("version")
    for target in ("enRoute", "arrived", "inService", "completed"):
        status, body = call(
            "POST",
            f"/v1/bookings/{booking_id}/transitions",
            MECH,
            {"to": target, "expectedVersion": version},
        )
        print("transition", target, status, body.get("status"))
        if status >= 400:
            print(body)
            raise SystemExit(3)
        version = body.get("version", version)
    _, final = call("GET", f"/v1/bookings/{booking_id}", CUST)
    _, jobs = call("GET", "/v1/bookings", MECH)
    mine = [item for item in jobs.get("items", []) if item.get("id") == booking_id]
    print(
        "customer",
        final.get("status"),
        final.get("mechanicDisplayName"),
        final.get("displayNumber"),
    )
    print("mechanic_job", mine[0]["status"] if mine else "missing")


if __name__ == "__main__":
    main()
