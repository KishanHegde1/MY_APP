import {
  Body,
  Controller,
  Put,
  UnauthorizedException,
  UseGuards,
  Version,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseOrJwtAuthGuard } from '../../common/guards/firebase-or-jwt-auth.guard';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { SavePickupLocationDto } from './dto/save-pickup-location.dto';
import { LocalRidesService } from './local-rides.service';

@ApiTags('users')
@Controller('users/me/pickup-location')
export class CurrentPickupLocationController {
  constructor(private readonly localRidesService: LocalRidesService) {}

  @Put()
  @Version('1')
  @UseGuards(FirebaseOrJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Save or replace the signed-in user\'s current pickup location',
  })
  saveCurrentPickup(
    @CurrentUser() user: JwtPayload | undefined,
    @Body() input: SavePickupLocationDto,
  ) {
    if (user == null) {
      throw new UnauthorizedException('Authentication is required.');
    }
    return this.localRidesService.saveCurrentPickup(user.sub, input);
  }
}
