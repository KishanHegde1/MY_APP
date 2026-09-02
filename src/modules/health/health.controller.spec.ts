import { HealthController } from './health.controller';

describe('HealthController', () => {
  it('returns the service health response', () => {
    expect(new HealthController().check()).toEqual({ success: true, status: 'ok', service: 'multi-service-backend' });
  });
});
