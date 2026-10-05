# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


LocalAuthGuard ใช้งานแค่ login เป็นหลัก
JwtAuthGuard ใช้ตอนเข้า API ที่ต้อง Login เป็นหลัก
RolesGuard ใช้ตรวจ "สิทธิ์"

## Mock Android purchase flow

The cart includes a development-only Google Play Billing simulation. In a debug
build, Checkout lets a tester choose success, failure, or cancellation. A
successful purchase calls `POST /iap/mock/purchases`; the backend creates a paid
order and payment, grants recipe access, and removes that recipe from the cart.

The backend always rejects mock purchases when `NODE_ENV=production`. Set
`IAP_MOCK_ENABLED=false` to disable them in another environment. Flutter release
builds hide the successful mock path by default; for a non-production release
test build, pass `--dart-define=ENABLE_MOCK_IAP=true` explicitly.

## Flutter config (dev / prod)

The app has no hardcoded URLs or IDs. Each environment's values live in
`frontend/config/*.json`, chosen with `--dart-define-from-file`:

```sh
cd frontend
flutter run --dart-define-from-file=config/dev.json                   # emulator -> backend on your machine
flutter build apk --release --dart-define-from-file=config/prod.json  # release build
```

| Key | Purpose |
| --- | --- |
| `API_BASE_URL` | backend URL (the emulator reaches the host machine at `10.0.2.2`; a real phone needs the computer's IP) |
| `GOOGLE_SERVER_CLIENT_ID` | Web client ID, same value as `GOOGLE_CLIENT_IDS` in the backend |
| `GOOGLE_IOS_CLIENT_ID` | iOS client ID (iOS builds only) |
| `ENABLE_MOCK_IAP` | optional; defaults to on for debug and off for release |

Running without a config file makes the app stop at startup and say that `API_BASE_URL` is not set.
