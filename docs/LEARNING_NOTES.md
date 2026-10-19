# Learning notes

A short guide for someone new to this repository. The specification is [PRD.md](PRD.md). Decisions are in [DECISIONS](DECISIONS/README.md).

## What we are building

A customer books a verified mechanic who comes to their bike or car. They can watch the mechanic on a map, chat, pay, and download a GST invoice. Mechanics have their own entry into the same app. Staff use an admin website built with Flutter web.

The phone is not allowed to decide that a job is paid or that a mechanic is verified. The server decides.

## How a booking moves

1. The screen calls a Riverpod notifier.
2. The notifier calls a use case.
3. The use case calls a port, which in the demo is a fake and in production is an HTTP adapter.
4. FastAPI checks the Firebase ID token, prices the job, and writes the booking with the Admin SDK.
5. Firestore Security Rules would reject the same write if the phone tried it directly.
6. Dispatch offers the job to one nearby mechanic for 45 seconds.
7. When the customer pays, Cashfree calls our webhook. We check the signature, then mark the booking paid.

If you can find those six steps in the folders, the architecture is doing its job.

## Where code lives (after M00)

| Folder | What |
| --- | --- |
| `app/lib/features/<name>/presentation` | Widgets |
| `app/lib/features/<name>/domain` | Rules and port interfaces |
| `app/lib/features/<name>/data/adapters` | The only place vendor SDKs may be imported |
| `app/lib/composition` | Which adapter is plugged in |
| `backend/app/api` | HTTP |
| `backend/app/application` | Use cases |
| `backend/app/domain` | Rules that must not import Firebase |
| `backend/app/adapters` | Firebase, Cashfree, Maps, Cloud Tasks |
| `firebase/` | Rules and emulator config |

Until M00, the Flutter demo is `mechanica_app/` and the API stub is `mechanica_api/main.py`.

## How to run the demo today

```bash
cd mechanica_app
flutter pub get
flutter run
```

Sign-in accepts `123456`. Data is fake and disappears when you restart. `flutter analyze` currently reports one real error: `test/widget_test.dart` still references `MyApp`. M01 fixes that.

## How to swap a provider later

Example: the team picks a different payment company.

1. Write a new class that implements `PaymentGateway`.
2. Change the config flag and the binding in `deps.py`.
3. Do not change the booking screen or the pricing code.

The same steps apply to auth, maps, and push. The matrix is in [chapter 07](prd/07-system-architecture.md).

## Words that matter

- **Port:** the interface.
- **Adapter:** the Cashfree or Firestore implementation.
- **Paise:** money stored as integers. ₹599.00 is `59900`.
- **Idempotency key:** the UUID that makes a double tap create one booking, not two.
- **Golden rule:** the phone reads live data. The server writes status and money.

More definitions are in [chapter 25](prd/25-glossary-and-appendices.md).
