import { HealthController } from '../src/modules/health/health.controller';
describe('Application scaffold', () => { it('reports healthy metadata', () => expect(new HealthController().check()).toEqual({ success: true, status: 'ok', service: 'multi-service-backend' })); });
