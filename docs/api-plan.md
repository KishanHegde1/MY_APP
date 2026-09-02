# API plan

The API uses the global prefix `/api` and URI versioning. Version 1 endpoints therefore use `/api/v1/...`. Swagger is exposed at `/api/docs` only when `SWAGGER_ENABLED=true`.

Implemented scaffold routes include health, authentication, users, local rides, and placeholder GET routes for the remaining services. The placeholders deliberately return success with `data: null`; they do not perform CRUD, payments, OTP delivery, ride matching, or live tracking.

Recommended sequence: authentication; profiles and addresses; local rides; provider onboarding; rentals; bookings; payments; notifications; chat; reviews; administration.
