import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateLocalRideBookings1785974500000
  implements MigrationInterface
{
  name = 'CreateLocalRideBookings1785974500000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      "CREATE TYPE \"bookings_service_type_enum\" AS ENUM ('LOCAL_BIKE_RIDE', 'LOCAL_AUTO_RIDE', 'LOCAL_CAR_RIDE', 'OUTSTATION_CAR_RIDE', 'BIKE_RENTAL', 'SELF_DRIVE_CAR_RENTAL', 'CAR_WITH_DRIVER_RENTAL', 'ROOM_RENTAL', 'HOUSE_RENTAL', 'APARTMENT_RENTAL', 'SHOP_RENTAL', 'OFFICE_RENTAL', 'WAREHOUSE_RENTAL', 'LAND_RENTAL')",
    );
    await queryRunner.query(
      "CREATE TYPE \"bookings_status_enum\" AS ENUM ('PENDING', 'CONFIRMED', 'CANCELLED', 'COMPLETED')",
    );
    await queryRunner.query(
      "CREATE TYPE \"bookings_selected_payment_method_enum\" AS ENUM ('CASH', 'UPI', 'CARD')",
    );
    await queryRunner.query(`
      CREATE TABLE "bookings" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "customer_id" uuid NOT NULL,
        "service_type" "bookings_service_type_enum" NOT NULL,
        "status" "bookings_status_enum" NOT NULL DEFAULT 'PENDING',
        "total_amount" numeric(12,2),
        "currency" character varying(3) NOT NULL DEFAULT 'INR',
        "selected_payment_method" "bookings_selected_payment_method_enum",
        "idempotency_key" character varying(128) NOT NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        "deleted_at" timestamptz,
        CONSTRAINT "PK_bookings" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_bookings_currency" CHECK ("currency" = 'INR'),
        CONSTRAINT "FK_bookings_customer" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(
      'CREATE INDEX "IDX_bookings_customer_status" ON "bookings" ("customer_id", "status")',
    );
    await queryRunner.query(
      'CREATE INDEX "IDX_bookings_service_type_status" ON "bookings" ("service_type", "status")',
    );
    await queryRunner.query(
      'CREATE UNIQUE INDEX "IDX_bookings_customer_idempotency" ON "bookings" ("customer_id", "idempotency_key")',
    );

    await queryRunner.query(
      "CREATE TYPE \"local_rides_vehicle_type_enum\" AS ENUM ('BIKE', 'AUTO', 'CAR')",
    );
    await queryRunner.query(
      "CREATE TYPE \"local_rides_route_source_enum\" AS ENUM ('GOOGLE_ROUTES', 'ESTIMATED_PREVIEW')",
    );
    await queryRunner.query(`
      CREATE TABLE "local_rides" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "booking_id" uuid NOT NULL,
        "customer_id" uuid NOT NULL,
        "pickup_latitude" numeric(10,7) NOT NULL,
        "pickup_longitude" numeric(10,7) NOT NULL,
        "pickup_address" character varying(500) NOT NULL,
        "drop_latitude" numeric(10,7) NOT NULL,
        "drop_longitude" numeric(10,7) NOT NULL,
        "drop_address" character varying(500) NOT NULL,
        "vehicle_type" "local_rides_vehicle_type_enum" NOT NULL,
        "route_id" character varying(120) NOT NULL,
        "route_title" character varying(120) NOT NULL,
        "route_source" "local_rides_route_source_enum" NOT NULL,
        "encoded_polyline" text,
        "distance_meters" integer NOT NULL,
        "duration_seconds" integer NOT NULL,
        "estimated_fare" numeric(12,2) NOT NULL,
        "currency" character varying(3) NOT NULL DEFAULT 'INR',
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        "deleted_at" timestamptz,
        CONSTRAINT "PK_local_rides" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_local_rides_booking" UNIQUE ("booking_id"),
        CONSTRAINT "CHK_local_rides_pickup_latitude" CHECK ("pickup_latitude" BETWEEN -90 AND 90),
        CONSTRAINT "CHK_local_rides_pickup_longitude" CHECK ("pickup_longitude" BETWEEN -180 AND 180),
        CONSTRAINT "CHK_local_rides_drop_latitude" CHECK ("drop_latitude" BETWEEN -90 AND 90),
        CONSTRAINT "CHK_local_rides_drop_longitude" CHECK ("drop_longitude" BETWEEN -180 AND 180),
        CONSTRAINT "CHK_local_rides_distance" CHECK ("distance_meters" BETWEEN 1000 AND 100000),
        CONSTRAINT "CHK_local_rides_duration" CHECK ("duration_seconds" BETWEEN 60 AND 43200),
        CONSTRAINT "CHK_local_rides_fare" CHECK ("estimated_fare" >= 0),
        CONSTRAINT "CHK_local_rides_currency" CHECK ("currency" = 'INR'),
        CONSTRAINT "CHK_local_rides_pickup_address" CHECK (char_length(btrim("pickup_address")) BETWEEN 3 AND 500),
        CONSTRAINT "CHK_local_rides_drop_address" CHECK (char_length(btrim("drop_address")) BETWEEN 3 AND 500),
        CONSTRAINT "FK_local_rides_booking" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE RESTRICT,
        CONSTRAINT "FK_local_rides_customer" FOREIGN KEY ("customer_id") REFERENCES "users"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(
      'CREATE INDEX "IDX_local_rides_customer_created_at" ON "local_rides" ("customer_id", "created_at")',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE "local_rides"');
    await queryRunner.query('DROP TYPE "local_rides_route_source_enum"');
    await queryRunner.query('DROP TYPE "local_rides_vehicle_type_enum"');
    await queryRunner.query('DROP TABLE "bookings"');
    await queryRunner.query('DROP TYPE "bookings_selected_payment_method_enum"');
    await queryRunner.query('DROP TYPE "bookings_status_enum"');
    await queryRunner.query('DROP TYPE "bookings_service_type_enum"');
  }
}
