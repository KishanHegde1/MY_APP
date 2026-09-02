import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BookingStatus } from '../../common/enums/booking-status.enum';
import { BaseEntity } from '../base.entity';
import { User } from '../user.entity';
import { Vehicle } from '../vehicle.entity';

export enum OutstationTripType {
  ONE_WAY = 'ONE_WAY',
  ROUND_TRIP = 'ROUND_TRIP',
}

@Entity({ name: 'outstation_rides' })
@Index(['customer', 'status'])
@Index(['departureAt'])
export class OutstationRide extends BaseEntity {
  @ManyToOne(() => User, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'customer_id' })
  customer!: User;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'driver_id' })
  driver?: User | null;

  @ManyToOne(() => Vehicle, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'vehicle_id' })
  vehicle?: Vehicle | null;

  @Column({ name: 'pickup_address', type: 'varchar', length: 500 })
  pickupAddress!: string;

  @Column({ name: 'destination_address', type: 'varchar', length: 500 })
  destinationAddress!: string;

  @Column({ name: 'trip_type', type: 'enum', enum: OutstationTripType })
  tripType!: OutstationTripType;

  @Column({ name: 'departure_at', type: 'timestamptz' })
  departureAt!: Date;

  @Column({ name: 'return_at', type: 'timestamptz', nullable: true })
  returnAt?: Date | null;

  @Column({ name: 'estimated_distance_km', type: 'decimal', precision: 8, scale: 2, nullable: true })
  estimatedDistanceKm?: string | null;

  @Column({ type: 'enum', enum: BookingStatus, default: BookingStatus.PENDING })
  status!: BookingStatus;
}
