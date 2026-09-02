import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  OneToOne,
} from 'typeorm';
import { BookingStatus } from '../common/enums/booking-status.enum';
import { PaymentMethod } from '../common/enums/payment-method.enum';
import { ServiceType } from '../common/enums/service-type.enum';
import { BaseEntity } from './base.entity';
import { LocalRide } from './local-ride.entity';
import { User } from './user.entity';

@Entity({ name: 'bookings' })
@Index(['customer', 'status'])
@Index(['serviceType', 'status'])
@Index(['customer', 'idempotencyKey'], { unique: true })
export class Booking extends BaseEntity {
  @ManyToOne(() => User, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'customer_id' })
  customer!: User;

  @Column({ name: 'service_type', type: 'enum', enum: ServiceType })
  serviceType!: ServiceType;

  @Column({
    type: 'enum',
    enum: BookingStatus,
    default: BookingStatus.PENDING,
  })
  status!: BookingStatus;

  @Column({
    name: 'total_amount',
    type: 'decimal',
    precision: 12,
    scale: 2,
    nullable: true,
  })
  totalAmount?: string | null;

  @Column({ type: 'varchar', length: 3, default: 'INR' })
  currency!: string;

  @Column({
    name: 'selected_payment_method',
    type: 'enum',
    enum: PaymentMethod,
    nullable: true,
  })
  selectedPaymentMethod?: PaymentMethod | null;

  @Column({ name: 'idempotency_key', type: 'varchar', length: 128 })
  idempotencyKey!: string;

  @OneToOne(() => LocalRide, (localRide) => localRide.booking)
  localRide?: LocalRide;
}
