# Multi-Service Application

A scalable foundation for local rides, outstation rides, vehicle rentals, room and property rentals, bookings, payments, notifications, chat, reviews, provider tools, and administration.

## Project layout

- The Flutter application is at this repository root.
- The NestJS API is in `backend/multi_service_backend`.
- Architecture notes are in `docs`.

Both frontend and backend foundations are created. Local-ride destination
resolution and route planning now use server-side Google Places (New) and
Google Routes integrations with a clearly labelled device/offline fallback.
Driver matching, live tracking, payments, and several provider workflows remain
planned integrations.

The planned Firebase authentication and Neon-backed profile ownership flow is
documented in `docs/authentication-and-profile-flow.md`.

Google Maps credentials, Android key restrictions, and the planned secure
routing-key split are documented in `docs/google-maps-platform-setup.md`.

## Start Flutter

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

On a physical Android phone, `localhost` means the phone itself. Connect the
phone and computer to the same network and use the computer's current LAN
address instead:

```powershell
ipconfig
flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IPV4:3000/api/v1
```

Debug builds allow this local HTTP connection. Production/profile builds must
use an HTTPS backend URL.

## Start the backend

```bash
cd backend/multi_service_backend
copy .env.development.example .env
npm install
npm run start:dev
```

With `SWAGGER_ENABLED=true`, health is available at `/api/v1/health` and Swagger at `/api/docs`.

## Recommended implementation order

Authentication; users and addresses; home navigation; local rides; driver onboarding; outstation rides; vehicle rentals; room/property rentals; bookings; payments; notifications; chat; reviews; provider tools; administration.
