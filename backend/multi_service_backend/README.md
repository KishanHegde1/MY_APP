# Multi-Service Backend

NestJS 11, TypeScript, PostgreSQL, TypeORM, Passport/JWT, validation, Swagger, rate limiting, security middleware, and test scaffolding for the multi-service platform.

## Setup

```bash
copy .env.development.example .env
npm install
npm run start:dev
```

The database connection is enabled when `DATABASE_URL` is defined. Keep `DATABASE_SYNCHRONIZE=false`; create and run migrations through the supplied npm scripts.

## Neon database

1. In the Neon Dashboard, open **Connection Details** and copy the **pooled** connection string into `DATABASE_URL` without removing its SSL or channel-binding query parameters.
2. Copy the **direct** connection string into `DATABASE_DIRECT_URL`. The running API uses the pooled URL; TypeORM migration commands use the direct URL.
3. Keep `DATABASE_SSL=true` and `DATABASE_SYNCHRONIZE=false`, then run `npm run migration:run` before starting the API.

If you prefer Neon’s SQL Editor, run
`sql/neon_user_pickup_locations.sql` instead. That script bootstraps the user,
role, and pickup tables transactionally. Use only one workflow; do not run the
manual SQL and TypeORM migrations against the same fresh database.

For local PostgreSQL, `DATABASE_DIRECT_URL` may be omitted (migrations fall back to `DATABASE_URL`) and `DATABASE_SSL` may be set to `false`.

Never put either database URL in Flutter or any other client app. Keep the real values only in this backend's ignored `.env` file, and never commit that file.

## Google Maps Platform

Enable the Google Routes API for the backend's Google Cloud project, then set `GOOGLE_ROUTES_API_KEY` only in the backend `.env`. Restrict the key to the Routes API and, in production, to the backend's egress IP addresses. Never put this server key in Flutter.

`POST /api/v1/maps/routes` accepts origin and destination coordinates and returns normalized route alternatives, encoded polylines, distances, traffic-aware durations, and clearly labelled indicative fare estimates. The API returns only alternatives within the inclusive `LOCAL_RIDE_MIN_DISTANCE_KM` to `LOCAL_RIDE_MAX_DISTANCE_KM` road-distance range. The defaults are 1 km and 100 km; both values must remain between 1 and 100, and the maximum cannot be lower than the minimum. Trips below the minimum receive a clear `400`; trips beyond the maximum are directed to outstation rides. When the Routes key is absent, the endpoint returns a safe `503` response rather than exposing configuration details.

The route endpoint is limited to 20 requests per minute per client. Paid route
search remains stateless; account-owned writes use the verified Firebase/JWT
guard described below.

Enable **Places API (New)** and set `GOOGLE_PLACES_API_KEY` to resolve typed
destinations through `POST /api/v1/maps/places/resolve`. The endpoint returns a
single normalized place and is limited to 30 requests per minute per client.
You may use one server key value for both environment variables when that key is
restricted to exactly **Routes API** and **Places API (New)**. Separate keys are
also supported. In production, add the backend's fixed outbound IP restriction.
The Places key must never be added to Flutter or an Android resource.

## Firebase identity and saved pickup

Set `FIREBASE_PROJECT_ID=multi-service-1f99d`. Local ID-token signature
verification works without placing a service-account private key in Flutter.
Production revocation checks require the server-only Firebase Admin credentials
shown in `.env.production.example`.

`PUT /api/v1/users/me/pickup-location` verifies the Firebase ID token (or a
valid backend JWT), maps the verified identity to a Neon user, and atomically
saves one current pickup with its exact coordinates, formatted address, and
selection source. The client cannot choose `user_id`.

## Razorpay payments

The Local Ride flow supports cash, UPI, and card choices. Cash creates a
`PENDING` ride request and does not charge the user. For UPI or card, the API
creates a Razorpay order, the Flutter app opens Razorpay Checkout, and the API
verifies the returned payment signature before it changes the booking to
`CONFIRMED` and the payment to `PAID`.

Set these values only in this backend's ignored `.env` file or in Render's
protected environment settings:

```env
PAYMENT_PROVIDER=razorpay
RAZORPAY_KEY_ID=rzp_test_your_key_id
RAZORPAY_KEY_SECRET=your_test_key_secret
RAZORPAY_WEBHOOK_SECRET=
```

Never add `RAZORPAY_KEY_SECRET` to Flutter, Android resources, a Git commit,
or a Firebase setting. Start with Razorpay **test** keys and switch to live
keys only after a full payment and refund test.

## Render deployment

This repository includes a root `render.yaml` Blueprint for the Nest API. In
Render, create a new Blueprint service from the Git repository, then enter the
values marked `sync: false` in `render.yaml` (Neon URL, Firebase credentials,
Maps keys, CORS origin, and Razorpay keys). The service health check is
`/api/v1/health`.

Run `npm run migration:run` against Neon from a trusted local terminal before
the first deployment. The Blueprint intentionally does not run migrations as a
Render free-plan pre-deploy command, so a failed migration never blocks or
partially mutates a deployment.

## Commands

```bash
npm run build
npm run lint
npm run test
npm run test:e2e
npm run migration:generate
npm run migration:run
```

The remaining feature endpoints return structured placeholder responses until their business logic is implemented. Local-ride booking, Razorpay checkout, and payment verification are live when `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` are set.
