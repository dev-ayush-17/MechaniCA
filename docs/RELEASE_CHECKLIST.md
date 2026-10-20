# Release checklist

M16 staging soak. Owner-only production steps. Agents do not run `firebase deploy` or `gcloud run deploy`.

## Do not ship

- Android `applicationId` / iOS bundle id still `com.example.*`. Today the demo uses `com.mechupp.app`; confirm Play Console and the Maps SHA restriction match that id before a store build. Do not ship a `com.example` id.
- Cashfree **sandbox** keys, Maps unrestricted keys, or `MECHUPP_APP_ENV=prod` pointed at localhost / `10.0.2.2`.
- Demo OTP hint (`123456`) in a release build. Dev flavor only. Fake auth is refused outside `dev`/`test`.
- Debug signing for a Play upload. Replace the Gradle debug `signingConfig` with the upload keystore.
- Unreviewed privacy policy URL (`https://mechupp.example/privacy` is a placeholder).

## Staging soak

1. Create the staging Firebase project and Cloud Run service in `asia-south1`. Do not reuse prod.
2. Set Flutter `--dart-define APP_ENV=staging` (or the staging config file) and `API_BASE_URL` to the staging Cloud Run URL.
3. Bind Cashfree **sandbox** and a Maps key restricted to the staging package name + SHA.
4. Confirm emulator-only HTTP. Staging and prod are HTTPS.
5. Smoke: sign-in OTP, quote, booking create (idempotent retry), payment pending until webhook, tracking share, invoice PDF, SOS payload, admin 1024 px gate.
6. Soak at least one weekday peak in the city you serve. Watch 5xx, webhook signature failures, and `rate_limited` on `/v1/payments` and `/v1/admin`.
7. Age checkbox stores `adultConfirmedAt` locally on the device. Server persistence of that field is still an owner follow-up.

## Rollback

| Layer | Rollback |
| --- | --- |
| Cloud Run | Route traffic to the previous revision. Do not delete the bad revision until payments drain. |
| Flutter | Halt the store rollout. Keep the previous Play / TestFlight build live. |
| Firestore rules | Redeploy the last known-good rules from git. Agents do not deploy. |
| Payments | If sandbox keys reached prod, rotate Cashfree secrets and pause capture. Mark incident SEV-1. |
| Webhook | Keep min instances at 1 in prod so cold start does not drop Cashfree. |

A payment or rules incident is stop-the-line: rotate the secret, restore rules, write an audit note. Feature work waits.

## Load notes (not a city simulation)

Small k6 or locust against `/health` and quote only. Do not script a full dispatch/payment city.

k6:

```bash
k6 run -e BASE=http://localhost:8000 - <<'JS'
import http from 'k6/http';
import { check, sleep } from 'k6';
export const options = { vus: 5, duration: '30s' };
export default function () {
  const base = __ENV.BASE;
  check(http.get(`${base}/health`), { 'health 200': (r) => r.status === 200 });
  http.post(`${base}/v1/quotes`, JSON.stringify({
    vehicleId: 'veh_book_1', serviceCode: 'general_service'
  }), { headers: { 'Content-Type': 'application/json', Authorization: 'Bearer fake:uid_book:+919876543210' } });
  sleep(1);
}
JS
```

locust:

```python
from locust import HttpUser, task

class HealthQuote(HttpUser):
    @task
    def health(self):
        self.client.get("/health")

    @task
    def quote(self):
        self.client.post("/v1/quotes", json={
            "vehicleId": "veh_book_1",
            "serviceCode": "general_service",
        })
```

`locust -f locustfile.py --host http://localhost:8000`

Quote requires a seeded vehicle and a bearer token in a real soak. `/health` does not.

## Owner-only launch (not this milestone)

- Production Firebase + GCP projects, secrets in Secret Manager.
- Live Cashfree + restricted Maps keys.
- GitHub branch protection on `main`.
- Lawyer review of the customer-facing privacy policy.
- Store listing, Play Integrity (backlog), and the real `applicationId` if it must change from `com.mechupp.app`.
