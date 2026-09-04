import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddLocalRideDriverTracking1785974700000
  implements MigrationInterface
{
  name = 'AddLocalRideDriverTracking1785974700000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('ALTER TABLE "local_rides" ADD COLUMN "driver_id" uuid');
    await queryRunner.query('ALTER TABLE "local_rides" ADD COLUMN "driver_accepted_at" timestamptz');
    await queryRunner.query('ALTER TABLE "local_rides" ADD COLUMN "driver_latitude" numeric(10,7)');
    await queryRunner.query('ALTER TABLE "local_rides" ADD COLUMN "driver_longitude" numeric(10,7)');
    await queryRunner.query('ALTER TABLE "local_rides" ADD COLUMN "driver_location_updated_at" timestamptz');
    await queryRunner.query('ALTER TABLE "local_rides" ADD CONSTRAINT "FK_local_rides_driver" FOREIGN KEY ("driver_id") REFERENCES "users"("id") ON DELETE SET NULL');
    await queryRunner.query('ALTER TABLE "local_rides" ADD CONSTRAINT "CHK_local_rides_driver_latitude" CHECK ("driver_latitude" IS NULL OR "driver_latitude" BETWEEN -90 AND 90)');
    await queryRunner.query('ALTER TABLE "local_rides" ADD CONSTRAINT "CHK_local_rides_driver_longitude" CHECK ("driver_longitude" IS NULL OR "driver_longitude" BETWEEN -180 AND 180)');
    await queryRunner.query('CREATE INDEX "IDX_local_rides_driver_created_at" ON "local_rides" ("driver_id", "created_at")');
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP INDEX "IDX_local_rides_driver_created_at"');
    await queryRunner.query('ALTER TABLE "local_rides" DROP CONSTRAINT "CHK_local_rides_driver_longitude"');
    await queryRunner.query('ALTER TABLE "local_rides" DROP CONSTRAINT "CHK_local_rides_driver_latitude"');
    await queryRunner.query('ALTER TABLE "local_rides" DROP CONSTRAINT "FK_local_rides_driver"');
    await queryRunner.query('ALTER TABLE "local_rides" DROP COLUMN "driver_location_updated_at"');
    await queryRunner.query('ALTER TABLE "local_rides" DROP COLUMN "driver_longitude"');
    await queryRunner.query('ALTER TABLE "local_rides" DROP COLUMN "driver_latitude"');
    await queryRunner.query('ALTER TABLE "local_rides" DROP COLUMN "driver_accepted_at"');
    await queryRunner.query('ALTER TABLE "local_rides" DROP COLUMN "driver_id"');
  }
}
