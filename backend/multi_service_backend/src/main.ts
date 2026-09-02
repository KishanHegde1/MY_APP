import { Logger, ValidationPipe, VersioningType } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import compression from 'compression';
import cookieParser from 'cookie-parser';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { GlobalExceptionFilter } from './common/filters/global-exception.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';
import { ResponseInterceptor } from './common/interceptors/response.interceptor';
import configuration from './config/configuration';
import { configureSwagger } from './config/swagger.config';

async function bootstrap(): Promise<void> {
  const config = configuration();
  const app = await NestFactory.create(AppModule, { bufferLogs: true });
  app.enableShutdownHooks(); app.useLogger(new Logger()); app.use(helmet()); app.use(compression()); app.use(cookieParser());
  app.enableCors({ origin: config.app.corsOrigins.length ? config.app.corsOrigins : true, credentials: true });
  app.setGlobalPrefix(config.app.apiPrefix); app.enableVersioning({ type: VersioningType.URI, defaultVersion: config.app.apiVersion });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }));
  app.useGlobalFilters(new GlobalExceptionFilter()); app.useGlobalInterceptors(new ResponseInterceptor(), new LoggingInterceptor());
  configureSwagger(app); await app.listen(config.app.port);
}
void bootstrap();
