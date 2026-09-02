-- Local ride booking storage for Neon.
-- Prerequisite: run neon_user_pickup_locations.sql first, or run
-- `npm.cmd run migration:run` instead. Do not use both manual SQL and
-- TypeORM migrations for the same database because manual SQL does not update
-- the typeorm_migrations table.

BEGIN;

DO $$
BEGIN
  IF to_regclass('public.users') IS NULL THEN
    RAISE EXCEPTION 'Missing users table. Run neon_user_pickup_locations.sql first.';
  END IF;
END
$$;

DO $$
BEGIN
  CREATE TYPE bookings_service_type_enum AS ENUM (
    'LOCAL_BIKE_RIDE', 'LOCAL_AUTO_RIDE', 'LOCAL_CAR_RIDE',
    'OUTSTATION_CAR_RIDE', 'BIKE_RENTAL', 'SELF_DRIVE_CAR_RENTAL',
    'CAR_WITH_DRIVER_RENTAL', 'ROOM_RENTAL', 'HOUSE_RENTAL',
    'APARTMENT_RENTAL', 'SHOP_RENTAL', 'OFFICE_RENTAL',
    'WAREHOUSE_RENTAL', 'LAND_RENTAL'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END
$$;

DO $$
BEGIN
  CREATE TYPE bookings_status_enum AS ENUM (
    'PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END
$$;

DO $$
BEGIN
  CREATE TYPE bookings_selected_payment_method_enum AS ENUM ('CASH', 'UPI', 'CARD');
EXCEPTION WHEN duplicate_object THEN NULL;
END
$$;

CREATE TABLE IF NOT EXISTS bookings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  service_type bookings_service_type_enum NOT NULL,
  status bookings_status_enum NOT NULL DEFAULT 'PENDING',
  total_amount numeric(12,2),
  currency varchar(3) NOT NULL DEFAULT 'INR' CHECK (currency = 'INR'),
  selected_payment_method bookings_selected_payment_method_enum,
  idempotency_key varchar(128) NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_bookings_customer_status
  ON bookings (customer_id, status);
CREATE INDEX IF NOT EXISTS idx_bookings_service_type_status
  ON bookings (service_type, status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_bookings_customer_idempotency
  ON bookings (customer_id, idempotency_key);

DO $$
BEGIN
  CREATE TYPE local_rides_vehicle_type_enum AS ENUM ('BIKE', 'AUTO', 'CAR');
EXCEPTION WHEN duplicate_object THEN NULL;
END
$$;

DO $$
BEGIN
  CREATE TYPE local_rides_route_source_enum AS ENUM (
    'GOOGLE_ROUTES', 'ESTIMATED_PREVIEW'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END
$$;

CREATE TABLE IF NOT EXISTS local_rides (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE RESTRICT,
  customer_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  pickup_latitude numeric(10,7) NOT NULL CHECK (pickup_latitude BETWEEN -90 AND 90),
  pickup_longitude numeric(10,7) NOT NULL CHECK (pickup_longitude BETWEEN -180 AND 180),
  pickup_address varchar(500) NOT NULL
    CHECK (char_length(btrim(pickup_address)) BETWEEN 3 AND 500),
  drop_latitude numeric(10,7) NOT NULL CHECK (drop_latitude BETWEEN -90 AND 90),
  drop_longitude numeric(10,7) NOT NULL CHECK (drop_longitude BETWEEN -180 AND 180),
  drop_address varchar(500) NOT NULL
    CHECK (char_length(btrim(drop_address)) BETWEEN 3 AND 500),
  vehicle_type local_rides_vehicle_type_enum NOT NULL,
  route_id varchar(120) NOT NULL,
  route_title varchar(120) NOT NULL,
  route_source local_rides_route_source_enum NOT NULL,
  encoded_polyline text,
  distance_meters integer NOT NULL CHECK (distance_meters BETWEEN 1000 AND 100000),
  duration_seconds integer NOT NULL CHECK (duration_seconds BETWEEN 60 AND 43200),
  estimated_fare numeric(12,2) NOT NULL CHECK (estimated_fare >= 0),
  currency varchar(3) NOT NULL DEFAULT 'INR' CHECK (currency = 'INR'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_local_rides_customer_created_at
  ON local_rides (customer_id, created_at);

COMMIT;

-- After booking a ride, this returns its saved map route and payment selection.
SELECT
  b.id AS booking_id,
  b.status,
  b.selected_payment_method,
  lr.vehicle_type,
  lr.pickup_address,
  lr.drop_address,
  lr.distance_meters,
  lr.duration_seconds,
  lr.estimated_fare,
  lr.created_at
FROM bookings b
JOIN local_rides lr ON lr.booking_id = b.id
ORDER BY lr.created_at DESC;
