import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateAuthCore1785974300000 implements MigrationInterface {
  name = 'CreateAuthCore1785974300000';

  async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('CREATE EXTENSION IF NOT EXISTS "pgcrypto"');
    await queryRunner.query(
      "CREATE TYPE \"users_status_enum\" AS ENUM ('PENDING', 'ACTIVE', 'SUSPENDED', 'DEACTIVATED')",
    );
    await queryRunner.query(`
      CREATE TABLE "users" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "email" character varying(255),
        "phone_number" character varying(32),
        "first_name" character varying(100),
        "last_name" character varying(100),
        "password_hash" character varying(255),
        "status" "users_status_enum" NOT NULL DEFAULT 'PENDING',
        "is_phone_verified" boolean NOT NULL DEFAULT false,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        "deleted_at" timestamptz,
        CONSTRAINT "PK_users" PRIMARY KEY ("id")
      )
    `);
    await queryRunner.query(
      'CREATE UNIQUE INDEX "IDX_users_email_active" ON "users" ("email") WHERE "deleted_at" IS NULL',
    );
    await queryRunner.query(
      'CREATE UNIQUE INDEX "IDX_users_phone_active" ON "users" ("phone_number") WHERE "deleted_at" IS NULL',
    );
    await queryRunner.query(
      "CREATE TYPE \"user_roles_role_enum\" AS ENUM ('CUSTOMER', 'DRIVER', 'VEHICLE_OWNER', 'PROPERTY_OWNER', 'SERVICE_PROVIDER', 'ADMIN', 'SUPPORT_STAFF')",
    );
    await queryRunner.query(`
      CREATE TABLE "user_roles" (
        "id" uuid NOT NULL DEFAULT gen_random_uuid(),
        "user_id" uuid NOT NULL,
        "role" "user_roles_role_enum" NOT NULL,
        "created_at" timestamptz NOT NULL DEFAULT now(),
        "updated_at" timestamptz NOT NULL DEFAULT now(),
        "deleted_at" timestamptz,
        CONSTRAINT "PK_user_roles" PRIMARY KEY ("id"),
        CONSTRAINT "FK_user_roles_user" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);
    await queryRunner.query(
      'CREATE UNIQUE INDEX "IDX_user_roles_user_role" ON "user_roles" ("user_id", "role")',
    );
  }

  async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE "user_roles"');
    await queryRunner.query('DROP TYPE "user_roles_role_enum"');
    await queryRunner.query('DROP TABLE "users"');
    await queryRunner.query('DROP TYPE "users_status_enum"');
  }
}
