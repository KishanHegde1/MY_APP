import { INestApplication, VersioningType } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { Server } from 'http';
import { AppModule } from '../src/app.module';

describe('Health endpoint (e2e)', () => {
  let app: INestApplication;
  beforeAll(async () => { const module = await Test.createTestingModule({ imports: [AppModule] }).compile(); app = module.createNestApplication(); app.setGlobalPrefix('api'); app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' }); await app.init(); });
  afterAll(async () => { await app.close(); });
  it('/api/v1/health (GET)', async () => { const server = app.getHttpServer() as Server; await request(server).get('/api/v1/health').expect(200).expect({ success: true, status: 'ok', service: 'multi-service-backend' }); });
});
