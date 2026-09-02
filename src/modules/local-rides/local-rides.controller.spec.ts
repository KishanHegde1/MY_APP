import {
  ExecutionContext,
  INestApplication,
  ValidationPipe,
  VersioningType,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { Server } from 'http';
import request from 'supertest';
import { FirebaseOrJwtAuthGuard } from '../../common/guards/firebase-or-jwt-auth.guard';
import { ResponseInterceptor } from '../../common/interceptors/response.interceptor';
import { PickupLocationSource } from '../../entities/user-pickup-location.entity';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { CurrentPickupLocationController } from './current-pickup-location.controller';
import {
  LocalRidesService,
  SavedPickupLocation,
} from './local-rides.service';

const userId = '2a9aeac8-4aa8-4c4c-9b42-7d7289ad4bcb';

describe('CurrentPickupLocationController', () => {
  let app: INestApplication;
  const saveCurrentPickup = jest.fn<Promise<SavedPickupLocation>, [string, unknown]>();

  beforeAll(async () => {
    const testingModule = await Test.createTestingModule({
      controllers: [CurrentPickupLocationController],
      providers: [
        {
          provide: LocalRidesService,
          useValue: { getScaffold: jest.fn(), saveCurrentPickup },
        },
      ],
    })
      .overrideGuard(FirebaseOrJwtAuthGuard)
      .useValue({
        canActivate(context: ExecutionContext): boolean {
          context
            .switchToHttp()
            .getRequest<{ user?: JwtPayload }>().user = {
            sub: userId,
            roles: [],
          };
          return true;
        },
      })
      .compile();
    app = testingModule.createNestApplication();
    app.setGlobalPrefix('api');
    app.enableVersioning({
      type: VersioningType.URI,
      defaultVersion: '1',
    });
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );
    app.useGlobalInterceptors(new ResponseInterceptor());
    await app.init();
  });

  afterAll(async () => app.close());
  afterEach(() => saveCurrentPickup.mockReset());

  it('registers authenticated PUT /api/v1/users/me/pickup-location', async () => {
    const saved: SavedPickupLocation = {
      id: '7a7f9477-f729-4dd6-bbe8-35887e87af17',
      latitude: 12.9715987,
      longitude: 77.594566,
      formattedAddress: 'MG Road, Bengaluru',
      source: PickupLocationSource.PIN,
      updatedAt: '2026-08-06T10:00:00.000Z',
    };
    saveCurrentPickup.mockResolvedValue(saved);

    const response = await request(app.getHttpServer() as Server)
      .put('/api/v1/users/me/pickup-location')
      .set('Authorization', 'Bearer verified-token')
      .send({
        latitude: 12.9715987,
        longitude: 77.594566,
        formattedAddress: '  MG Road, Bengaluru  ',
        source: 'MAP_PIN',
      })
      .expect(200);

    expect(saveCurrentPickup).toHaveBeenCalledWith(userId, {
      latitude: 12.9715987,
      longitude: 77.594566,
      formattedAddress: 'MG Road, Bengaluru',
      source: PickupLocationSource.PIN,
    });
    expect(response.body).toEqual({ success: true, data: saved });
  });

  it('rejects a client-supplied user id instead of trusting it', async () => {
    await request(app.getHttpServer() as Server)
      .put('/api/v1/users/me/pickup-location')
      .set('Authorization', 'Bearer verified-token')
      .send({
        userId: '7949e32a-8827-45fe-99ad-9aafe81a139c',
        latitude: 12.9715987,
        longitude: 77.594566,
        formattedAddress: 'MG Road, Bengaluru',
        source: PickupLocationSource.PIN,
      })
      .expect(400);

    expect(saveCurrentPickup).not.toHaveBeenCalled();
  });

  it.each([
    { latitude: 91, longitude: 77.5, formattedAddress: 'Valid address', source: 'GPS' },
    { latitude: 12.9, longitude: 181, formattedAddress: 'Valid address', source: 'PIN' },
    { latitude: 12.9, longitude: 77.5, formattedAddress: '  ', source: 'MANUAL' },
    { latitude: 12.9, longitude: 77.5, formattedAddress: 'Valid address', source: 'RAW_UID' },
  ])('rejects invalid pickup payload %#', async (body) => {
    await request(app.getHttpServer() as Server)
      .put('/api/v1/users/me/pickup-location')
      .set('Authorization', 'Bearer verified-token')
      .send(body)
      .expect(400);
  });
});
