import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FirebaseOrJwtAuthGuard } from '../../common/guards/firebase-or-jwt-auth.guard';
import { Booking } from '../../entities/booking.entity';
import { LocalRide } from '../../entities/local-ride.entity';
import { Payment } from '../../entities/payment.entity';
import { UserPickupLocation } from '../../entities/user-pickup-location.entity';
import { FirebaseAuthModule } from '../../integrations/firebase/firebase-auth.module';
import { RazorpayGatewayService } from '../../integrations/razorpay/razorpay-gateway.service';
import { AuthModule } from '../auth/auth.module';
import { CurrentPickupLocationController } from './current-pickup-location.controller';
import { LocalRidesController } from './local-rides.controller';
import { LocalRidesService } from './local-rides.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([UserPickupLocation, Booking, LocalRide, Payment]),
    AuthModule,
    FirebaseAuthModule,
  ],
  controllers: [LocalRidesController, CurrentPickupLocationController],
  providers: [
    LocalRidesService,
    FirebaseOrJwtAuthGuard,
    RazorpayGatewayService,
  ],
})
export class LocalRidesModule {}
