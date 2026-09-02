import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateUserPickupLocations1785974400000
  implements MigrationInterface
{
  name = 'CreateUserPickupLocations1785974400000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      'ALTER TABLE "users" ADD COLUMN "firebase_uid" character varying(128)',
    );
    await queryRunner.query(
      'CREATE UNIQUE INDEX "IDX_users_firebase_uid" ON "users" ("firebase_uid") WHERE "firebase_uid" IS NOT NULL',
    );
    await queryRunner.query(
      "CREATE TYPE \"pickup_location_source_enum\" AS ENUM ('GPS', 'MANUAL', 'PIN')",
    );
    await queryRunner.query(`
      CREATE TABLE "user_pickup_locations" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "latitude" numeric(10,7) NOT NULL,
        "longitude" numeric(10,7) NOT NULL,
        "formatted_address" character varying(500) NOT NULL,
        "source" "pickup_location_source_enum" NOT NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        "deleted_at" timestamptz,
        CONSTRAINT "PK_user_pickup_locations" PRIMARY KEY ("id"),
        CONSTRAINT "UQ_user_pickup_locations_user_id" UNIQUE ("user_id"),
        CONSTRAINT "CHK_user_pickup_locations_latitude" CHECK ("latitude" BETWEEN -90 AND 90),
        CONSTRAINT "CHK_user_pickup_locations_longitude" CHECK ("longitude" BETWEEN -180 AND 180),
        CONSTRAINT "CHK_user_pickup_locations_address" CHECK (char_length(btrim("formatted_address")) BETWEEN 3 AND 500),
        CONSTRAINT "FK_user_pickup_locations_user" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE "user_pickup_locations"');
    await queryRunner.query('DROP TYPE "pickup_location_source_enum"');
    await queryRunner.query('DROP INDEX "IDX_users_firebase_uid"');
    await queryRunner.query(
      'ALTER TABLE "users" DROP COLUMN "firebase_uid"',
    );
  }
}
