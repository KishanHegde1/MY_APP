import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { ApplicationConfiguration } from './configuration';
import { AuditLog } from '../entities/audit-log.entity';
import { Booking } from '../entities/booking.entity';
import { LocalRide } from '../entities/local-ride.entity';
import { Payment } from '../entities/payment.entity';
import { Property } from '../entities/property.entity';
import { User } from '../entities/user.entity';
import { UserPickupLocation } from '../entities/user-pickup-location.entity';
import { UserRole } from '../entities/user-role.entity';
import { Vehicle } from '../entities/vehicle.entity';
import { SCAFFOLD_ENTITIES } from '../entities/scaffolds';

export const entities = [User, UserRole, UserPickupLocation, Vehicle, Property, Booking, Payment, LocalRide, AuditLog, ...SCAFFOLD_ENTITIES];
export const createTypeOrmOptions = (config: ApplicationConfiguration, databaseUrl = config.database.url): TypeOrmModuleOptions => ({
  type: 'postgres', url: databaseUrl, entities, migrations: [__dirname + '/../database/migrations/*{.ts,.js}'], migrationsTableName: 'typeorm_migrations',
  synchronize: config.app.environment !== 'production' && config.database.synchronize, logging: config.database.logging,
  ssl: config.database.ssl ? { rejectUnauthorized: false } : false, extra: { max: config.database.poolMax, enableChannelBinding: config.database.ssl },
});
