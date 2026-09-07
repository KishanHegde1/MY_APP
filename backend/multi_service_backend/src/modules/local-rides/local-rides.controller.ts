import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Put,
  UnauthorizedException,
  UseGuards,
  Version,
} from '@nestjs/common';
import { isUUID } from 'class-validator';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { FirebaseOrJwtAuthGuard } from '../../common/guards/firebase-or-jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { UserRoleType } from '../../common/enums/user-role.enum';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { CreateLocalRideBookingDto } from './dto/create-local-ride-booking.dto';
import { VerifyRazorpayPaymentDto } from './dto/verify-razorpay-payment.dto';
import { UpdateDriverLocationDto } from './dto/update-driver-location.dto';
import { LocalRidesService } from './local-rides.service';

@ApiTags('local-rides')
@Controller('local-rides')
export class LocalRidesController {
  constructor(private readonly localRidesService: LocalRidesService) {}

  @Get()
  @Version('1')
  getScaffold() {
    return this.localRidesService.getScaffold();
  }

  @Get('bookings')
  @Version('1')
  @UseGuards(FirebaseOrJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'List the authenticated customer’s local-ride bookings',
    description:
      'Returns saved ride details and the current booking/payment status. Driver assignment and live GPS tracking are added separately.',
  })
  listBookings(@CurrentUser() user: JwtPayload | undefined) {
    if (user == null) {
      throw new UnauthorizedException('Authentication is required.');
    }
    return this.localRidesService.listBookings(user.sub);
  }

  @Post('bookings')
  @Version('1')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(FirebaseOrJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Create an authenticated local-ride request from a confirmed route',
    description:
      'Stores an estimated route and payment-method selection. It does not charge the customer or assign a driver.',
  })
  @ApiResponse({ status: HttpStatus.CREATED, description: 'Ride request saved.' })
  createBooking(
    @CurrentUser() user: JwtPayload | undefined,
    @Headers('idempotency-key') idempotencyKey: string | undefined,
    @Body() input: CreateLocalRideBookingDto,
  ) {
    if (user == null) {
      throw new UnauthorizedException('Authentication is required.');
    }
    if (idempotencyKey == null || !isUUID(idempotencyKey)) {
      throw new BadRequestException('A valid Idempotency-Key header is required.');
    }
    return this.localRidesService.createBooking(
      user.sub,
      idempotencyKey,
      input,
    );
  }

  @Post('bookings/:bookingId/razorpay/order')
  @Version('1')
  @HttpCode(HttpStatus.CREATED)
  @UseGuards(FirebaseOrJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Create a Razorpay order for an existing local-ride booking',
  })
  createRazorpayOrder(
    @CurrentUser() user: JwtPayload | undefined,
    @Param('bookingId') bookingId: string,
  ) {
    if (user == null) {
      throw new UnauthorizedException('Authentication is required.');
    }
    if (!isUUID(bookingId)) {
      throw new BadRequestException('A valid booking ID is required.');
    }
    return this.localRidesService.createRazorpayOrder(user.sub, bookingId);
  }

  @Post('bookings/:bookingId/razorpay/verify')
  @Version('1')
  @HttpCode(HttpStatus.OK)
  @UseGuards(FirebaseOrJwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({
    summary: 'Verify a Razorpay payment signature and confirm the ride booking',
  })
  verifyRazorpayPayment(
    @CurrentUser() user: JwtPayload | undefined,
    @Param('bookingId') bookingId: string,
    @Body() input: VerifyRazorpayPaymentDto,
  ) {
    if (user == null) {
      throw new UnauthorizedException('Authentication is required.');
    }
    if (!isUUID(bookingId)) {
      throw new BadRequestException('A valid booking ID is required.');
    }
    return this.localRidesService.verifyRazorpayPayment(
      user.sub,
      bookingId,
      input,
    );
  }

}

@ApiTags('driver-local-rides')
@Controller('driver/local-rides')
@UseGuards(FirebaseOrJwtAuthGuard, RolesGuard)
@Roles(UserRoleType.DRIVER)
@ApiBearerAuth()
export class DriverLocalRidesController {
  constructor(private readonly localRidesService: LocalRidesService) {}

  @Get('requests')
  @Version('1')
  @ApiOperation({
    summary: 'List unassigned local-ride requests available to a driver',
  })
  listRequests(@CurrentUser() user: JwtPayload | undefined) {
    if (user == null) {
      throw new UnauthorizedException('Authentication is required.');
    }
    return this.localRidesService.listDriverRideRequests(user.sub);
  }

  @Get('active')
  @Version('1')
  @ApiOperation({ summary: 'Get the driver\'s active accepted local ride' })
  activeRide(@CurrentUser() user: JwtPayload | undefined) {
    if (user == null) {
      throw new UnauthorizedException('Authentication is required.');
    }
    return this.localRidesService.listDriverActiveRide(user.sub);
  }

  @Post(':rideId/accept')
  @Version('1')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Atomically accept an available local-ride request as a driver',
  })
  acceptRide(
    @CurrentUser() user: JwtPayload | undefined,
    @Param('rideId') rideId: string,
  ) {
    if (user == null) {
      throw new UnauthorizedException('Authentication is required.');
    }
    return this.localRidesService.acceptRide(user.sub, rideId);
  }

  @Put(':rideId/location')
  @Version('1')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Store one foreground driver GPS update for an accepted local ride',
    description:
      'The driver app sends this about once per second while the active ride screen is open. Background tracking is intentionally not enabled by this endpoint.',
  })
  updateLocation(
    @CurrentUser() user: JwtPayload | undefined,
    @Param('rideId') rideId: string,
    @Body() input: UpdateDriverLocationDto,
  ) {
    if (user == null) {
      throw new UnauthorizedException('Authentication is required.');
    }
    return this.localRidesService.updateDriverLocation(
      user.sub,
      rideId,
      input.latitude,
      input.longitude,
    );
  }
}
