import { Controller, Get, Version } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

@ApiTags('health')
@Controller('health')
export class HealthController {
  @Get() @Version('1')
  check(): { success: true; status: 'ok'; service: string } { return { success: true, status: 'ok', service: 'multi-service-backend' }; }
}
