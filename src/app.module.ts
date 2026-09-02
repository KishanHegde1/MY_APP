import 'dotenv/config';
import { MiddlewareConsumer, Module, NestModule } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { TypeOrmModule } from '@nestjs/typeorm';
import configuration from './config/configuration';
import { envValidationSchema } from './config/env.validation';
import { createTypeOrmOptions } from './config/typeorm.config';
import { RequestIdMiddleware } from './common/middleware/request-id.middleware';
import { IntegrationModulesModule } from './integrations/integration-modules.module';
import { AuthModule } from './modules/auth/auth.module';
import { HealthModule } from './modules/health/health.module';
import { LocalRidesModule } from './modules/local-rides/local-rides.module';
import { PlaceholderModulesModule } from './modules/placeholder-modules.module';
import { UsersModule } from './modules/users/users.module';

const databaseImports = process.env.DATABASE_URL ? [TypeOrmModule.forRoot(createTypeOrmOptions(configuration()))] : [];

@Module({ imports: [ConfigModule.forRoot({ isGlobal: true, load: [configuration], validationSchema: envValidationSchema }), ThrottlerModule.forRoot([{ ttl: 60000, limit: 100 }]), ...databaseImports, HealthModule, AuthModule, UsersModule, LocalRidesModule, PlaceholderModulesModule, IntegrationModulesModule] })
export class AppModule implements NestModule { configure(consumer: MiddlewareConsumer): void { consumer.apply(RequestIdMiddleware).forRoutes('*'); } }
