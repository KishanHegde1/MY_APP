import { plainToInstance } from 'class-transformer';
import { validate } from 'class-validator';
import { ComputeRoutesDto, RideVehicleType } from './compute-routes.dto';

describe('ComputeRoutesDto', () => {
  it('accepts valid nested latitude and longitude values', async () => {
    const dto = plainToInstance(ComputeRoutesDto, {
      origin: { latitude: 12.9716, longitude: 77.5946 },
      destination: { latitude: 12.9352, longitude: 77.6245 },
      alternatives: true,
      vehicleType: RideVehicleType.bike,
    });

    await expect(validate(dto)).resolves.toEqual([]);
  });

  it('rejects an invalid nested coordinate', async () => {
    const dto = plainToInstance(ComputeRoutesDto, {
      origin: { latitude: 120, longitude: 77.5946 },
      destination: { latitude: 12.9352, longitude: 77.6245 },
    });

    const errors = await validate(dto);

    expect(errors.some((error) => error.property === 'origin')).toBe(true);
  });

  it.each([
    { latitude: 'NaN', longitude: 77.5946 },
    { latitude: 12.9716, longitude: 181 },
  ])('rejects non-finite and out-of-range coordinates', async (origin) => {
    const dto = plainToInstance(ComputeRoutesDto, {
      origin,
      destination: { latitude: 12.9352, longitude: 77.6245 },
    });

    const errors = await validate(dto);

    expect(errors.some((error) => error.property === 'origin')).toBe(true);
  });

  it('rejects an unsupported vehicle type', async () => {
    const dto = plainToInstance(ComputeRoutesDto, {
      origin: { latitude: 12.9716, longitude: 77.5946 },
      destination: { latitude: 12.9352, longitude: 77.6245 },
      vehicleType: 'BUS',
    });

    const errors = await validate(dto);

    expect(errors.some((error) => error.property === 'vehicleType')).toBe(true);
  });
});
