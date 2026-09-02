import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
} from 'typeorm';
import { PaymentStatus } from '../common/enums/payment-status.enum';
import { BaseEntity } from './base.entity';
import { Booking } from './booking.entity';

@Entity({ name: 'payments' })
@Index(['booking', 'status'])
@Index(['provider', 'providerReference'], { unique: true })
export class Payment extends BaseEntity {
  @ManyToOne(() => Booking, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'booking_id' })
  booking!: Booking;

  @Column({
    type: 'enum',
    enum: PaymentStatus,
    default: PaymentStatus.PENDING,
  })
  status!: PaymentStatus;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount!: string;

  @Column({ type: 'varchar', length: 50, nullable: true })
  provider?: string | null;

  /// Razorpay order ID. This is safe to store, but never store the secret key.
  @Column({ name: 'provider_reference', type: 'varchar', length: 255, nullable: true })
  providerReference?: string | null;

  @Column({ name: 'provider_payment_id', type: 'varchar', length: 255, nullable: true })
  providerPaymentId?: string | null;

  @Column({ name: 'provider_signature', type: 'varchar', length: 255, nullable: true })
  providerSignature?: string | null;
}
