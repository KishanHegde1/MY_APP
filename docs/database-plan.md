# Database plan

The entity foundation covers users and multiple user roles, addresses/devices, driver/provider profiles, vehicles and documents, properties/rooms, ride and rental bookings, payments/transactions/wallets, notifications/chat, reviews/favourites/coupons, and audit logs.

One account can own many `UserRole` rows, supporting combinations such as customer plus property owner. Monetary columns use PostgreSQL decimals, coordinates use decimals, primary keys use UUIDs, and entities inherit creation/update/soft-delete timestamps.

`synchronize` stays disabled by default and must remain disabled in production. Set `DATABASE_URL`, generate the initial migration with `npm run migration:generate`, inspect it, and apply it with `npm run migration:run`.
