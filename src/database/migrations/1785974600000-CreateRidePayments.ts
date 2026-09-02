import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateRidePayments1785974600000 implements MigrationInterface {
  name = 'CreateRidePayments1785974600000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      "CREATE TYPE \"payments_status_enum\" AS ENUM ('PENDING', 'PAID', 'FAILED', 'REFUNDED')",
    );
    await queryRunner.query(`
      CREATE TABLE "payments" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "booking_id" uuid NOT NULL,
        "status" "payments_status_enum" NOT NULL DEFAULT 'PENDING',
        "amount" numeric(12,2) NOT NULL,
        "provider" character varying(50),
        "provider_reference" character varying(255),
        "provider_payment_id" character varying(255),
        "provider_signature" character varying(255),
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        "deleted_at" timestamptz,
        CONSTRAINT "PK_payments" PRIMARY KEY ("id"),
        CONSTRAINT "CHK_payments_amount" CHECK ("amount" >= 0),
        CONSTRAINT "FK_payments_booking" FOREIGN KEY ("booking_id") REFERENCES "bookings"("id") ON DELETE RESTRICT
      )
    `);
    await queryRunner.query(
      'CREATE INDEX "IDX_payments_booking_status" ON "payments" ("booking_id", "status")',
    );
    await queryRunner.query(
      'CREATE UNIQUE INDEX "IDX_payments_provider_reference" ON "payments" ("provider", "provider_reference") WHERE "provider_reference" IS NOT NULL',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE "payments"');
    await queryRunner.query('DROP TYPE "payments_status_enum"');
  }
}
