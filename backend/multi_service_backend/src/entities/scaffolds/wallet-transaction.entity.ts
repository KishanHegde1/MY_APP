import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../base.entity';
import { Wallet } from './wallet.entity';

export enum WalletTransactionDirection {
  CREDIT = 'CREDIT',
  DEBIT = 'DEBIT',
}

@Entity({ name: 'wallet_transactions' })
@Index(['wallet', 'createdAt'])
@Index(['reference'])
export class WalletTransaction extends BaseEntity {
  @ManyToOne(() => Wallet, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'wallet_id' })
  wallet!: Wallet;

  @Column({ type: 'enum', enum: WalletTransactionDirection })
  direction!: WalletTransactionDirection;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount!: string;

  @Column({ name: 'balance_after', type: 'decimal', precision: 12, scale: 2 })
  balanceAfter!: string;

  @Column({ type: 'varchar', length: 255, nullable: true })
  reference?: string | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  description?: string | null;
}
