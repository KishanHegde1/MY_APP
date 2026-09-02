# Backend structure

The backend lives in `backend/multi_service_backend`.

- `src/config`: environment, Swagger, and TypeORM configuration.
- `src/common`: reusable DTOs, enums, guards, middleware, filters, interceptors, and utilities.
- `src/entities`: PostgreSQL/TypeORM entity skeletons with UUID identifiers and audit timestamps.
- `src/modules`: health, authentication, users, local rides, and placeholder service modules.
- `src/integrations`: replaceable maps, payments, notifications, storage, and SMS adapters.
- `src/database`: TypeORM data source, migrations, and seeding entry point.
- `test`: end-to-end tests.

To add a module, create its controller, service, DTOs, interfaces, and module class, then import the module into `AppModule`. To add an entity, register it in `src/config/typeorm.config.ts`, generate a migration, review the SQL, and run the migration.
