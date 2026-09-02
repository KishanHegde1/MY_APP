import { INestApplication, ValidationPipe, VersioningType } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { ThrottlerModule } from '@nestjs/throttler';
import { Server } from 'http';
import request from 'supertest';
import { GlobalExceptionFilter } from '../../common/filters/global-exception.filter';
import { ResponseInterceptor } from '../../common/interceptors/response.interceptor';
import { RideVehicleType } from './dto/compute-routes.dto';
import { MapsModule } from './maps.module';
import { MapsService } from './maps.service';
import { ComputeRoutesResult } from './maps.types';

describe('MapsController', () => {
  let app: INestApplication;
  let rateLimitApp: INestApplication;
  const computeRoutes = jest.fn<Promise<ComputeRoutesResult>, [unknown]>();

  beforeAll(async () => {
    app = await createTestApp(computeRoutes);
    rateLimitApp = await createTestApp(computeRoutes);
  });

  afterAll(async () => {
    await app.close();
    await rateLimitApp.close();
  });
  afterEach(() => computeRoutes.mockReset());

  it('registers POST /api/v1/maps/routes and uses the global success envelope', async () => {
    const normalizedResult: ComputeRoutesResult = {
      origin: { latitude: 12.9716, longitude: 77.5946 },
      destination: { latitude: 12.9352, longitude: 77.6245 },
      vehicleType: RideVehicleType.car,
      providerTravelMode: 'DRIVE',
      alternativesRequested: true,
      generatedAt: '2026-08-05T12:00:00.000Z',
      routes: [],
      fareDisclaimer: 'Indicative estimate only.',
    };
    computeRoutes.mockResolvedValue(normalizedResult);

    const response = await request(app.getHttpServer() as Server)
      .post('/api/v1/maps/routes')
      .send({ origin: normalizedResult.origin, destination: normalizedResult.destination })
      .expect(200);

    expect(response.body).toEqual({ success: true, data: normalizedResult });
    expect(computeRoutes).toHaveBeenCalledWith({
      origin: normalizedResult.origin,
      destination: normalizedResult.destination,
    });
  });

  it('rejects invalid coordinates before calling the provider', async () => {
    await request(app.getHttpServer() as Server)
      .post('/api/v1/maps/routes')
      .send({
        origin: { latitude: 1000, longitude: 77.5946 },
        destination: { latitude: 12.9352, longitude: 77.6245 },
      })
      .expect(400);

    expect(computeRoutes).not.toHaveBeenCalled();
  });

  it('limits this paid endpoint to 20 requests per minute per client', async () => {
    const result: ComputeRoutesResult = {
      origin: { latitude: 12.9716, longitude: 77.5946 },
      destination: { latitude: 12.9352, longitude: 77.6245 },
      vehicleType: RideVehicleType.car,
      providerTravelMode: 'DRIVE',
      alternativesRequested: true,
      generatedAt: '2026-08-05T12:00:00.000Z',
      routes: [],
      fareDisclaimer: 'Indicative estimate only.',
    };
    computeRoutes.mockResolvedValue(result);
    const server = rateLimitApp.getHttpServer() as Server;
    const body = { origin: result.origin, destination: result.destination };

    for (let index = 0; index < 20; index += 1) {
      await request(server).post('/api/v1/maps/routes').send(body).expect(200);
    }
    await request(server).post('/api/v1/maps/routes').send(body).expect(429);
  });
});

async function createTestApp(
  computeRoutes: jest.Mock<Promise<ComputeRoutesResult>, [unknown]>,
): Promise<INestApplication> {
  const testingModule = await Test.createTestingModule({
    imports: [ThrottlerModule.forRoot([{ ttl: 60_000, limit: 100 }]), MapsModule],
  })
    .overrideProvider(MapsService)
    .useValue({ computeRoutes })
    .compile();
  const app = testingModule.createNestApplication();
  app.setGlobalPrefix('api');
  app.enableVersioning({ type: VersioningType.URI, defaultVersion: '1' });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true, forbidNonWhitelisted: true }));
  app.useGlobalFilters(new GlobalExceptionFilter());
  app.useGlobalInterceptors(new ResponseInterceptor());
  await app.init();
  return app;
}
