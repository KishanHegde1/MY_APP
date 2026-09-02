import { UnauthorizedException } from '@nestjs/common';
import { DataSource, Repository } from 'typeorm';
import { RazorpayGatewayService } from '../../integrations/razorpay/razorpay-gateway.service';
import {
  PickupLocationSource,
  UserPickupLocation,
} from '../../entities/user-pickup-location.entity';
import { LocalRidesService } from './local-rides.service';

const userId = '2a9aeac8-4aa8-4c4c-9b42-7d7289ad4bcb';

describe('LocalRidesService', () => {
  const upsert = jest.fn();
  const findOneBy = jest.fn();
  const repository = { upsert, findOneBy } as unknown as Repository<UserPickupLocation>;
  const dataSource = { transaction: jest.fn() } as unknown as DataSource;
  const razorpay = {} as RazorpayGatewayService;
  const service = new LocalRidesService(repository, dataSource, razorpay);

  beforeEach(() => jest.resetAllMocks());

  it('atomically upserts one exact current pickup for the authenticated user', async () => {
    upsert.mockResolvedValue({ identifiers: [], generatedMaps: [], raw: [] });
    findOneBy.mockResolvedValue({
      id: '7a7f9477-f729-4dd6-bbe8-35887e87af17',
      userId,
      latitude: '12.9715987',
      longitude: '77.5945660',
      formattedAddress: 'MG Road, Bengaluru',
      source: PickupLocationSource.PIN,
      updatedAt: new Date('2026-08-06T10:00:00.000Z'),
    });

    const result = await service.saveCurrentPickup(userId, {
      latitude: 12.9715987,
      longitude: 77.594566,
      formattedAddress: 'MG Road, Bengaluru',
      source: PickupLocationSource.PIN,
    });

    expect(upsert).toHaveBeenCalledWith(
      {
        userId,
        latitude: '12.9715987',
        longitude: '77.5945660',
        formattedAddress: 'MG Road, Bengaluru',
        source: PickupLocationSource.PIN,
        deletedAt: null,
      },
      {
        conflictPaths: ['userId'],
        skipUpdateIfNoValuesChanged: false,
      },
    );
    expect(findOneBy).toHaveBeenCalledWith({ userId });
    expect(result).toEqual({
      id: '7a7f9477-f729-4dd6-bbe8-35887e87af17',
      latitude: 12.9715987,
      longitude: 77.594566,
      formattedAddress: 'MG Road, Bengaluru',
      source: PickupLocationSource.PIN,
      updatedAt: '2026-08-06T10:00:00.000Z',
    });
    expect(result).not.toHaveProperty('userId');
  });

  it('rejects a non-UUID identity even though it did not come from the body', async () => {
    await expect(
      service.saveCurrentPickup('raw-firebase-uid', {
        latitude: 12.9716,
        longitude: 77.5946,
        formattedAddress: 'MG Road, Bengaluru',
        source: PickupLocationSource.GPS,
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);

    expect(upsert).not.toHaveBeenCalled();
  });
});
