import {
  BookingStatus,
} from '../../common/enums/booking-status.enum';
import {
  Injectable,
  BadRequestException,
  InternalServerErrorException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { isUUID } from 'class-validator';
import { DataSource, In, Repository } from 'typeorm';
import { API_PLACEHOLDER_MESSAGE } from '../../common/constants/app.constants';
import { LocalRideVehicleType } from '../../common/enums/local-ride-vehicle-type.enum';
import { ServiceType } from '../../common/enums/service-type.enum';
import { Booking } from '../../entities/booking.entity';
import { LocalRide } from '../../entities/local-ride.entity';
import { Payment } from '../../entities/payment.entity';
import { User } from '../../entities/user.entity';
import { PaymentStatus } from '../../common/enums/payment-status.enum';
import { RazorpayGatewayService } from '../../integrations/razorpay/razorpay-gateway.service';
import {
  PickupLocationSource,
  UserPickupLocation,
} from '../../entities/user-pickup-location.entity';
import { SavePickupLocationDto } from './dto/save-pickup-location.dto';
import { CreateLocalRideBookingDto } from './dto/create-local-ride-booking.dto';
import { VerifyRazorpayPaymentDto } from './dto/verify-razorpay-payment.dto';

export interface SavedPickupLocation {
  id: string;
  latitude: number;
  longitude: number;
  formattedAddress: string;
  source: PickupLocationSource;
  updatedAt: string;
}

export interface CreatedLocalRideBooking {
  bookingId: string;
  rideId: string;
  status: BookingStatus;
  paymentMethod: string;
  estimatedFare: number;
  currency: 'INR';
}

export interface RazorpayCheckoutOrder {
  bookingId: string;
  razorpayOrderId: string;
  amount: number;
  currency: 'INR';
  keyId: string;
}

export interface VerifiedRazorpayPayment {
  bookingId: string;
  rideId: string;
  paymentId: string;
  paymentStatus: PaymentStatus.PAID;
  bookingStatus: BookingStatus.CONFIRMED;
  estimatedFare: number;
  currency: 'INR';
}

export interface LocalRideBookingSummary {
  bookingId: string;
  rideId: string;
  status: BookingStatus;
  paymentMethod: string;
  paymentStatus: PaymentStatus | null;
  estimatedFare: number;
  currency: 'INR';
  vehicleType: LocalRideVehicleType;
  pickup: {
    latitude: number;
    longitude: number;
    label: string;
  };
  destination: {
    latitude: number;
    longitude: number;
    label: string;
  };
  distanceKm: number;
  durationMinutes: number;
  createdAt: string;
  trackingAvailable: false;
  trackingMessage: string;
}

@Injectable()
export class LocalRidesService {
  constructor(
    @InjectRepository(UserPickupLocation)
    private readonly pickupLocations: Repository<UserPickupLocation>,
    @InjectDataSource()
    private readonly dataSource: DataSource,
    private readonly razorpay: RazorpayGatewayService,
  ) {}

  getScaffold() {
    // TODO: enforce the configured minimum and maximum local-ride distances again when a booking is created.
    return { success: true, message: API_PLACEHOLDER_MESSAGE, data: null };
  }

  async saveCurrentPickup(
    authenticatedUserId: string,
    input: SavePickupLocationDto,
  ): Promise<SavedPickupLocation> {
    if (!isUUID(authenticatedUserId)) {
      throw new UnauthorizedException('Invalid authenticated user.');
    }

    await this.pickupLocations.upsert(
      {
        userId: authenticatedUserId,
        latitude: input.latitude.toFixed(7),
        longitude: input.longitude.toFixed(7),
        formattedAddress: input.formattedAddress,
        source: input.source,
        deletedAt: null,
      },
      {
        conflictPaths: ['userId'],
        skipUpdateIfNoValuesChanged: false,
      },
    );

    const saved = await this.pickupLocations.findOneBy({
      userId: authenticatedUserId,
    });
    if (saved == null) {
      throw new InternalServerErrorException(
        'The pickup location could not be saved.',
      );
    }
    return {
      id: saved.id,
      latitude: Number(saved.latitude),
      longitude: Number(saved.longitude),
      formattedAddress: saved.formattedAddress,
      source: saved.source,
      updatedAt: saved.updatedAt.toISOString(),
    };
  }

  async createBooking(
    authenticatedUserId: string,
    idempotencyKey: string,
    input: CreateLocalRideBookingDto,
  ): Promise<CreatedLocalRideBooking> {
    if (!isUUID(authenticatedUserId)) {
      throw new UnauthorizedException('Invalid authenticated user.');
    }

    return this.dataSource.transaction(async (manager) => {
      const bookings = manager.getRepository(Booking);
      const rides = manager.getRepository(LocalRide);
      const existing = await bookings.findOne({
        where: {
          customer: { id: authenticatedUserId },
          idempotencyKey,
        },
      });
      if (existing != null) {
        const ride = await rides.findOne({
          where: { booking: { id: existing.id } },
        });
        if (ride == null) {
          throw new InternalServerErrorException(
            'The existing ride request could not be loaded.',
          );
        }
        return this.bookingResponse(existing, ride);
      }

      // This is an estimated fare snapshot only. It is never a captured or
      // final charge; a payment gateway and driver assignment must re-verify it.
      const booking = await bookings.save(
        bookings.create({
          customer: { id: authenticatedUserId } as User,
          serviceType: this.serviceTypeFor(input.vehicleType),
          status: BookingStatus.PENDING,
          totalAmount: input.estimatedFare.toFixed(2),
          currency: 'INR',
          selectedPaymentMethod: input.paymentMethod,
          idempotencyKey,
        }),
      );
      const ride = await rides.save(
        rides.create({
          booking,
          customer: { id: authenticatedUserId } as User,
          pickupLatitude: input.pickup.latitude.toFixed(7),
          pickupLongitude: input.pickup.longitude.toFixed(7),
          pickupAddress: input.pickup.label.trim(),
          dropLatitude: input.destination.latitude.toFixed(7),
          dropLongitude: input.destination.longitude.toFixed(7),
          dropAddress: input.destination.label.trim(),
          vehicleType: input.vehicleType,
          routeId: input.routeId.trim(),
          routeTitle: input.routeTitle.trim(),
          routeSource: input.routeSource,
          encodedPolyline: input.encodedPolyline?.trim() || null,
          distanceMeters: Math.round(input.distanceKm * 1000),
          durationSeconds: input.durationMinutes * 60,
          estimatedFare: input.estimatedFare.toFixed(2),
          currency: 'INR',
        }),
      );
      return this.bookingResponse(booking, ride);
    });
  }

  async listBookings(
    authenticatedUserId: string,
  ): Promise<LocalRideBookingSummary[]> {
    this.assertAuthenticatedUser(authenticatedUserId);
    const rides = await this.dataSource.getRepository(LocalRide).find({
      where: { customer: { id: authenticatedUserId } },
      relations: { booking: true },
      order: { createdAt: 'DESC' },
    });
    if (rides.length === 0) return [];

    const bookingIds = rides.map((ride) => ride.booking.id);
    const payments = await this.dataSource.getRepository(Payment).find({
      where: { booking: { id: In(bookingIds) } },
      relations: { booking: true },
      order: { createdAt: 'DESC' },
    });
    const paymentStatusByBookingId = new Map<string, PaymentStatus>();
    for (const payment of payments) {
      if (!paymentStatusByBookingId.has(payment.booking.id)) {
        paymentStatusByBookingId.set(payment.booking.id, payment.status);
      }
    }

    return rides.map((ride) =>
      this.bookingSummaryResponse(
        ride,
        paymentStatusByBookingId.get(ride.booking.id) ?? null,
      ),
    );
  }

  async createRazorpayOrder(
    authenticatedUserId: string,
    bookingId: string,
  ): Promise<RazorpayCheckoutOrder> {
    this.assertAuthenticatedUser(authenticatedUserId);
    const bookings = this.dataSource.getRepository(Booking);
    const rides = this.dataSource.getRepository(LocalRide);
    const payments = this.dataSource.getRepository(Payment);
    const booking = await bookings.findOne({
      where: { id: bookingId, customer: { id: authenticatedUserId } },
    });
    if (booking == null) {
      throw new NotFoundException('Ride booking was not found.');
    }
    if (
      booking.selectedPaymentMethod === 'CASH' ||
      booking.selectedPaymentMethod == null
    ) {
      throw new BadRequestException(
        'Choose UPI or card before starting a Razorpay payment.',
      );
    }
    if (booking.status !== BookingStatus.PENDING) {
      throw new BadRequestException('This ride booking cannot be paid now.');
    }
    const ride = await rides.findOne({ where: { booking: { id: booking.id } } });
    if (ride == null) {
      throw new InternalServerErrorException('Ride details could not be loaded.');
    }
    const existing = await payments.findOne({
      where: {
        booking: { id: booking.id },
        provider: 'razorpay',
        status: PaymentStatus.PENDING,
      },
      order: { createdAt: 'DESC' },
    });
    if (existing?.providerReference != null) {
      return {
        bookingId: booking.id,
        razorpayOrderId: existing.providerReference,
        amount: Math.round(Number(existing.amount) * 100),
        currency: 'INR',
        keyId: this.razorpay.keyId(),
      };
    }

    const order = await this.razorpay.createOrder({
      amountInPaise: Math.round(Number(ride.estimatedFare) * 100),
      receipt: `ride_${booking.id.replace(/-/g, '').slice(0, 32)}`,
      bookingId: booking.id,
    });
    await payments.save(
      payments.create({
        booking,
        status: PaymentStatus.PENDING,
        amount: ride.estimatedFare,
        provider: 'razorpay',
        providerReference: order.id,
      }),
    );
    return {
      bookingId: booking.id,
      razorpayOrderId: order.id,
      amount: order.amount,
      currency: 'INR',
      keyId: this.razorpay.keyId(),
    };
  }

  async verifyRazorpayPayment(
    authenticatedUserId: string,
    bookingId: string,
    input: VerifyRazorpayPaymentDto,
  ): Promise<VerifiedRazorpayPayment> {
    this.assertAuthenticatedUser(authenticatedUserId);
    if (
      !this.razorpay.verifySignature({
        orderId: input.razorpayOrderId,
        paymentId: input.razorpayPaymentId,
        signature: input.razorpaySignature,
      })
    ) {
      throw new BadRequestException('Razorpay payment verification failed.');
    }
    return this.dataSource.transaction(async (manager) => {
      const bookings = manager.getRepository(Booking);
      const rides = manager.getRepository(LocalRide);
      const payments = manager.getRepository(Payment);
      const booking = await bookings.findOne({
        where: { id: bookingId, customer: { id: authenticatedUserId } },
      });
      if (booking == null) {
        throw new NotFoundException('Ride booking was not found.');
      }
      const payment = await payments.findOne({
        where: {
          booking: { id: booking.id },
          provider: 'razorpay',
          providerReference: input.razorpayOrderId,
        },
      });
      if (payment == null) {
        throw new NotFoundException('Razorpay order was not found.');
      }
      if (
        payment.status === PaymentStatus.PAID &&
        booking.status === BookingStatus.CONFIRMED
      ) {
        const existingRide = await rides.findOne({
          where: { booking: { id: booking.id } },
        });
        if (existingRide == null) {
          throw new InternalServerErrorException('Ride details could not be loaded.');
        }
        return this.verifiedPaymentResponse(booking, existingRide, payment);
      }
      if (booking.status !== BookingStatus.PENDING) {
        throw new BadRequestException('This ride booking cannot be paid now.');
      }
      payment.status = PaymentStatus.PAID;
      payment.providerPaymentId = input.razorpayPaymentId;
      payment.providerSignature = input.razorpaySignature;
      await payments.save(payment);
      booking.status = BookingStatus.CONFIRMED;
      await bookings.save(booking);
      const ride = await rides.findOne({ where: { booking: { id: booking.id } } });
      if (ride == null) {
        throw new InternalServerErrorException('Ride details could not be loaded.');
      }
      return this.verifiedPaymentResponse(booking, ride, payment);
    });
  }

  private bookingResponse(
    booking: Booking,
    ride: LocalRide,
  ): CreatedLocalRideBooking {
    return {
      bookingId: booking.id,
      rideId: ride.id,
      status: booking.status,
      paymentMethod: booking.selectedPaymentMethod ?? 'CASH',
      estimatedFare: Number(ride.estimatedFare),
      currency: 'INR',
    };
  }

  private bookingSummaryResponse(
    ride: LocalRide,
    paymentStatus: PaymentStatus | null,
  ): LocalRideBookingSummary {
    const booking = ride.booking;
    return {
      bookingId: booking.id,
      rideId: ride.id,
      status: booking.status,
      paymentMethod: booking.selectedPaymentMethod ?? 'CASH',
      paymentStatus,
      estimatedFare: Number(ride.estimatedFare),
      currency: 'INR',
      vehicleType: ride.vehicleType,
      pickup: {
        latitude: Number(ride.pickupLatitude),
        longitude: Number(ride.pickupLongitude),
        label: ride.pickupAddress,
      },
      destination: {
        latitude: Number(ride.dropLatitude),
        longitude: Number(ride.dropLongitude),
        label: ride.dropAddress,
      },
      distanceKm: ride.distanceMeters / 1000,
      durationMinutes: Math.ceil(ride.durationSeconds / 60),
      createdAt: ride.createdAt.toISOString(),
      trackingAvailable: false,
      trackingMessage:
        booking.status === BookingStatus.CONFIRMED
          ? 'Payment is confirmed. Driver assignment and live tracking will appear here once a driver accepts the ride.'
          : 'Your ride request is saved. Driver assignment and live tracking will appear here once available.',
    };
  }

  private verifiedPaymentResponse(
    booking: Booking,
    ride: LocalRide,
    payment: Payment,
  ): VerifiedRazorpayPayment {
    return {
      bookingId: booking.id,
      rideId: ride.id,
      paymentId: payment.providerPaymentId ?? '',
      paymentStatus: PaymentStatus.PAID,
      bookingStatus: BookingStatus.CONFIRMED,
      estimatedFare: Number(ride.estimatedFare),
      currency: 'INR',
    };
  }

  private assertAuthenticatedUser(authenticatedUserId: string): void {
    if (!isUUID(authenticatedUserId)) {
      throw new UnauthorizedException('Invalid authenticated user.');
    }
  }

  private serviceTypeFor(vehicle: LocalRideVehicleType): ServiceType {
    return {
      [LocalRideVehicleType.BIKE]: ServiceType.LOCAL_BIKE_RIDE,
      [LocalRideVehicleType.AUTO]: ServiceType.LOCAL_AUTO_RIDE,
      [LocalRideVehicleType.CAR]: ServiceType.LOCAL_CAR_RIDE,
    }[vehicle];
  }
}
