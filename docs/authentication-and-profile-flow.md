# Authentication and profile flow

## Security boundary

The Flutter application must never connect to Neon directly and must never
contain `DATABASE_URL`. The connection string belongs only in
`backend/multi_service_backend/.env`.

1. Flutter authenticates the person with Firebase Authentication.
2. Flutter sends the short-lived Firebase ID token to the NestJS API.
3. NestJS verifies that token with Firebase Admin.
4. NestJS finds or creates the matching Neon user by the verified Firebase UID.
5. NestJS returns the application session and profile-completion state.
6. Flutter loads profile data from `GET /api/v1/users/me`.

## Supported entry paths

### Email and password

1. Collect full name, email, password confirmation, and an optional phone.
2. Create the Firebase email/password identity.
3. Send the verified Firebase ID token plus the submitted profile fields to the
   backend session endpoint.
4. Upsert the Neon user and return `profileComplete`.
5. Send an email-verification message and clearly show verification status.

### Phone OTP

1. Collect a phone number in E.164 format and obtain consent for SMS use.
2. Firebase sends and verifies the one-time code.
3. Send the verified Firebase ID token to the backend.
4. If required profile fields are missing, route to `/complete-profile`.
5. Collect full name and email, then save them through the authenticated API.

Do not ask for unnecessary personal data during registration. Addresses,
preferences, provider documents, and payment information should be collected
only when the user starts the related workflow.

## Profile source of truth

Firebase owns authentication identifiers and verification state. Neon owns the
application profile. Recommended user fields are:

- `firebase_uid` (unique and immutable)
- `email` and `is_email_verified`
- `phone_number` and `is_phone_verified`
- `first_name` and `last_name`
- `profile_completed_at`
- `status`, timestamps, and soft-delete fields

Never trust a UID, verified email, or verified phone supplied as ordinary JSON.
Read those values from the Firebase token after server-side verification.

## Planned backend contract

- `POST /api/v1/auth/firebase/session` — verify the Firebase ID token, upsert
  the Neon user, and establish an application session.
- `GET /api/v1/users/me` — return only the authenticated user's profile.
- `PATCH /api/v1/users/me/onboarding` — validate and save required profile
  details after phone registration.
- `POST /api/v1/auth/logout` — revoke the application refresh token.

The session response should include `profileComplete`. Route incomplete users
to `/complete-profile`; route complete users to `/home`.

## Account linking

If a person later adds phone, email/password, or Google sign-in, link the new
credential to the already signed-in Firebase user. Linked providers retain one
Firebase UID and therefore one Neon profile. Do not create a second profile by
matching unverified client-submitted email addresses.

## Required configuration before activation

- Enable Email/Password and Phone providers in Firebase Authentication.
- Add Android SHA fingerprints and the platform Firebase configuration files.
- Configure Firebase Admin credentials only on the backend.
- Configure Firebase test phone numbers before sending real SMS messages.
- Apply Neon migrations before enabling profile writes.
