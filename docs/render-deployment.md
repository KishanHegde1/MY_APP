# Deploy the backend to Render

## Before deployment

1. Push this folder to a private GitHub repository. The root `render.yaml`
   tells Render that the backend lives in `backend/multi_service_backend`.
2. In Neon, copy a fresh **pooled** URL to `DATABASE_URL` and a fresh
   **direct** URL to `DATABASE_DIRECT_URL`. Do not put either URL in Flutter.
3. From a trusted local terminal in `backend/multi_service_backend`, use the
   direct Neon URL and run `npm run migration:run`. This creates the local ride
   booking and payment tables.
4. Create Razorpay test keys in the Razorpay Dashboard. Keep both values
   private; the secret is server-only.

## Create the Render service

1. Open the Render Dashboard and select **New** > **Blueprint**.
2. Connect the GitHub repository and select its `main` branch.
3. Render reads `render.yaml`. Confirm the proposed service named
   `multi-service-backend`, then create it.
4. Enter every value marked as private in the Environment page:

   ```env
   DATABASE_URL=<Neon pooled URL>
   DATABASE_DIRECT_URL=<Neon direct URL>
   FIREBASE_CLIENT_EMAIL=<Firebase service-account client email>
   FIREBASE_PRIVATE_KEY=<Firebase service-account private key, including line breaks>
   GOOGLE_ROUTES_API_KEY=<server-restricted Google Routes key>
   GOOGLE_PLACES_API_KEY=<server-restricted Google Places key>
   PAYMENT_PROVIDER=razorpay
   RAZORPAY_KEY_ID=rzp_test_<your_key_id>
   RAZORPAY_KEY_SECRET=<your_test_key_secret>
   CORS_ORIGIN=<your web app URL, if you deploy a web client>
   ```

   Native Android and iPhone applications do not need a browser CORS origin,
   but a web build does.

5. Deploy and open `https://<your-render-service>.onrender.com/api/v1/health`.
   A successful response confirms the API is running.
6. Set the Flutter app's API base URL to
   `https://<your-render-service>.onrender.com/api/v1` before a release build.

## Payment safety

The Flutter app receives only the public Razorpay key ID returned with an order.
It never stores the Razorpay secret. The server checks the payment signature
before marking a booking as paid. Test a successful payment, failed payment,
and cancellation with Razorpay test mode before enabling live keys.
