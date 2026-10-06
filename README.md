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

The backend always rejects mock purchases when `APP_ENV=production`. On
`development` and `staging` they are allowed; set `IAP_MOCK_ENABLED=false` to
disable them there.

`APP_ENV` (`development` | `staging` | `production`) controls app behavior and is
separate from `NODE_ENV` (the Docker image always sets `NODE_ENV=production`).
Only `development` auto-syncs the database schema; `staging` and `production`
must run `npm run migration:run`. If `APP_ENV` is not set, `NODE_ENV=production`
counts as `production` and anything else as `development`. Flutter release
builds hide the successful mock path by default; for a non-production release
test build, pass `--dart-define=ENABLE_MOCK_IAP=true` explicitly.

## Flutter config (dev / staging / prod)

The app has no hardcoded URLs or IDs. Each environment's values live in
`frontend/config/*.json`, chosen with `--dart-define-from-file`:

```sh
cd frontend
flutter run --dart-define-from-file=config/dev.json                   # emulator -> backend on your machine
flutter build apk --release --dart-define-from-file=config/staging.json  # staging backend for testing
flutter build apk --release --dart-define-from-file=config/prod.json  # release build
```

Frontend CI builds a debug APK when frontend files change. It selects
`config/prod.json` for `main` or `prod`, `config/staging.json` for `develop`
or `staging`, and `config/dev.json` for other branches. Pull requests use their
source branch.

| Key | Purpose |
| --- | --- |
| `API_BASE_URL` | backend URL (the emulator reaches the host machine at `10.0.2.2`; a real phone needs the computer's IP) |
| `GOOGLE_SERVER_CLIENT_ID` | Web client ID, same value as `GOOGLE_CLIENT_IDS` in the backend |
| `GOOGLE_IOS_CLIENT_ID` | iOS client ID (iOS builds only) |
| `ENABLE_MOCK_IAP` | optional; defaults to on for debug and off for release |

Running without a config file makes the app stop at startup and say that `API_BASE_URL` is not set.

## Demo data (seed)

`npm run seed` (in `backend/`) **wipes every table** and fills the database with
data that looks like the app has been used for about six months:

- 20 users: 1 admin, 5 creators, 14 users (2 of them signed up with Google)
- 100 recipes (official for sale, free community recipes, drafts, hidden/rejected)
- orders, payments, purchased recipes, reviews, comments, favorites, carts, banners

Every account with a password uses `Password123!`, for example
`admin@recipy.local`, `chef.mook@recipy.local`, `somchai@example.com`.
The seed refuses to run when `APP_ENV` is `staging` or `production`
unless `SEED_ALLOW_RESET=true` is set. Data lives in
`backend/src/database/seeds/demo-data.ts`.
