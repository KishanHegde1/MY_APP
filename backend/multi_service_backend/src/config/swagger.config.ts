import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import configuration from './configuration';

export const configureSwagger = (app: INestApplication): void => {
  const config = configuration();
  if (!config.swagger.enabled) return;
  const document = SwaggerModule.createDocument(app, new DocumentBuilder().setTitle('Multi-Service API').setDescription('Scaffold API for the multi-service platform.').setVersion(`v${config.app.apiVersion}`).addBearerAuth().build());
  SwaggerModule.setup('docs', app, document, { useGlobalPrefix: true });
};
