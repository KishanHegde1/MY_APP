import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { PaymentStatus } from '../../common/enums/payment-status.enum';
import { BaseEntity } from '../base.entity';
import { Payment } from '../payment.entity';
import { User } from '../user.entity';

export enum TransactionType {
  CHARGE = 'CHARGE',
  REFUND = 'REFUND',
  PAYOUT = 'PAYOUT',
}

@Entity({ name: 'transactions' })
@Index(['payment', 'status'])
@Index(['externalReference'])
export class Transaction extends BaseEntity {
  @ManyToOne(() => Payment, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'payment_id' })
  payment?: Payment | null;

  @ManyToOne(() => User, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ type: 'enum', enum: TransactionType })
  type!: TransactionType;

  @Column({ type: 'enum', enum: PaymentStatus, default: PaymentStatus.PENDING })
  status!: PaymentStatus;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount!: string;

  @Column({ type: 'char', length: 3, default: 'INR' })
  currency!: string;

  @Column({ name: 'external_reference', type: 'varchar', length: 255, nullable: true })
  externalReference?: string | null;
}
