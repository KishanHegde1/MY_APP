-- Preferred option: run `npm run migration:run` after setting a fresh Neon
-- DATABASE_DIRECT_URL. Use this script only if you are applying SQL manually.
-- It requires the bookings table created by neon_local_ride_bookings.sql.

BEGIN;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'payments_status_enum') THEN
    CREATE TYPE payments_status_enum AS ENUM ('PENDING', 'PAID', 'FAILED', 'REFUNDED');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id uuid NOT NULL REFERENCES bookings(id) ON DELETE RESTRICT,
  status payments_status_enum NOT NULL DEFAULT 'PENDING',
  amount numeric(12,2) NOT NULL CHECK (amount >= 0),
  provider varchar(50),
  provider_reference varchar(255),
  provider_payment_id varchar(255),
  provider_signature varchar(255),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_payments_booking_status
  ON payments (booking_id, status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_provider_reference
  ON payments (provider, provider_reference)
  WHERE provider_reference IS NOT NULL;

COMMIT;

-- Verify your saved payment records:
SELECT
  p.id,
  p.status AS payment_status,
  p.amount,
  p.provider,
  p.provider_reference AS razorpay_order_id,
  p.provider_payment_id AS razorpay_payment_id,
  b.status AS booking_status,
  p.created_at
FROM payments p
JOIN bookings b ON b.id = p.booking_id
ORDER BY p.created_at DESC;
