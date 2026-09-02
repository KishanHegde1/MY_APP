# Migrations

The first migrations create the Firebase-linked user/auth core and the user's
current pickup-location table. Against Neon, keep `DATABASE_SYNCHRONIZE=false`
and run:

```bash
npm run migration:run
```

The SQL-editor alternative is `sql/neon_user_pickup_locations.sql`. Choose one
workflow only: do not paste the SQL script after TypeORM migrations (or run the
migrations after the manual script), because the manual workflow does not add
rows to TypeORM's migration-history table.
