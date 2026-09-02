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
  UnauthorizedException,
  UseGuards,
  Version,
} from '@nestjs/common';
import { isUUID } from 'class-validator';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseOrJwtAuthGuard } from '../../common/guards/firebase-or-jwt-auth.guard';
import { JwtPayload } from '../auth/interfaces/jwt-payload.interface';
import { CreateLocalRideBookingDto } from './dto/create-local-ride-booking.dto';
import { VerifyRazorpayPaymentDto } from './dto/verify-razorpay-payment.dto';
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
