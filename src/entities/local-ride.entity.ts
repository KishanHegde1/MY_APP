import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToOne,
} from 'typeorm';
import { LocalRideRouteSource } from '../common/enums/local-ride-route-source.enum';
import { LocalRideVehicleType } from '../common/enums/local-ride-vehicle-type.enum';
import { BaseEntity } from './base.entity';
import { Booking } from './booking.entity';
import { User } from './user.entity';

@Entity({ name: 'local_rides' })
@Index(['customer', 'createdAt'])
export class LocalRide extends BaseEntity {
  @OneToOne(() => Booking, (booking) => booking.localRide, {
    nullable: false,
    onDelete: 'RESTRICT',
  })
  @JoinColumn({ name: 'booking_id' })
  booking!: Booking;

  @ManyToOne(() => User, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'customer_id' })
  customer!: User;

  @Column({ name: 'pickup_latitude', type: 'decimal', precision: 10, scale: 7 })
  pickupLatitude!: string;

  @Column({ name: 'pickup_longitude', type: 'decimal', precision: 10, scale: 7 })
  pickupLongitude!: string;

  @Column({ name: 'pickup_address', type: 'varchar', length: 500 })
  pickupAddress!: string;

  @Column({ name: 'drop_latitude', type: 'decimal', precision: 10, scale: 7 })
  dropLatitude!: string;

  @Column({ name: 'drop_longitude', type: 'decimal', precision: 10, scale: 7 })
  dropLongitude!: string;

  @Column({ name: 'drop_address', type: 'varchar', length: 500 })
  dropAddress!: string;

  @Column({ name: 'vehicle_type', type: 'enum', enum: LocalRideVehicleType })
  vehicleType!: LocalRideVehicleType;

  @Column({ name: 'route_id', type: 'varchar', length: 120 })
  routeId!: string;

  @Column({ name: 'route_title', type: 'varchar', length: 120 })
  routeTitle!: string;

  @Column({
    name: 'route_source',
    type: 'enum',
    enum: LocalRideRouteSource,
  })
  routeSource!: LocalRideRouteSource;

  @Column({ name: 'encoded_polyline', type: 'text', nullable: true })
  encodedPolyline?: string | null;

  @Column({ name: 'distance_meters', type: 'integer' })
  distanceMeters!: number;

  @Column({ name: 'duration_seconds', type: 'integer' })
  durationSeconds!: number;

  @Column({ name: 'estimated_fare', type: 'decimal', precision: 12, scale: 2 })
  estimatedFare!: string;

  @Column({ type: 'varchar', length: 3, default: 'INR' })
  currency!: string;
}
