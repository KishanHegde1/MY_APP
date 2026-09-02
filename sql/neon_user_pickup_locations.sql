-- Neon bootstrap for authenticated pickup persistence.
-- Run this whole script in the Neon SQL Editor for the database configured by
-- DATABASE_URL. It is idempotent when rerun. If you use TypeORM migrations,
-- run `npm run migration:run` instead of this manual script (do not run both).

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
  CREATE TYPE users_status_enum AS ENUM (
    'PENDING', 'ACTIVE', 'SUSPENDED', 'DEACTIVATED'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END
$$;

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  firebase_uid varchar(128),
  email varchar(255),
  phone_number varchar(32),
  first_name varchar(100),
  last_name varchar(100),
  password_hash varchar(255),
  status users_status_enum NOT NULL DEFAULT 'PENDING',
  is_phone_verified boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS firebase_uid varchar(128);

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_firebase_uid
  ON users (firebase_uid)
  WHERE firebase_uid IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_active
  ON users (email)
  WHERE deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone_active
  ON users (phone_number)
  WHERE deleted_at IS NULL;

DO $$
BEGIN
  CREATE TYPE user_roles_role_enum AS ENUM (
    'CUSTOMER',
    'DRIVER',
    'VEHICLE_OWNER',
    'PROPERTY_OWNER',
    'SERVICE_PROVIDER',
    'ADMIN',
    'SUPPORT_STAFF'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END
$$;

CREATE TABLE IF NOT EXISTS user_roles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  role user_roles_role_enum NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT fk_user_roles_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_roles_user_role
  ON user_roles (user_id, role);

DO $$
BEGIN
  CREATE TYPE pickup_location_source_enum AS ENUM ('GPS', 'MANUAL', 'PIN');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END
$$;

CREATE TABLE IF NOT EXISTS user_pickup_locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  latitude numeric(10,7) NOT NULL,
  longitude numeric(10,7) NOT NULL,
  formatted_address varchar(500) NOT NULL,
  source pickup_location_source_enum NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  CONSTRAINT uq_user_pickup_locations_user_id UNIQUE (user_id),
  CONSTRAINT fk_user_pickup_locations_user
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT chk_user_pickup_locations_latitude
    CHECK (latitude BETWEEN -90 AND 90),
  CONSTRAINT chk_user_pickup_locations_longitude
    CHECK (longitude BETWEEN -180 AND 180),
  CONSTRAINT chk_user_pickup_locations_address
    CHECK (char_length(btrim(formatted_address)) BETWEEN 3 AND 500)
);

COMMIT;

-- Verification: these three rows must be returned.
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('users', 'user_roles', 'user_pickup_locations')
ORDER BY table_name;
