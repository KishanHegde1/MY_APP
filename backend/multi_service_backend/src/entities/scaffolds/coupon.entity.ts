import { Column, Entity, Index } from 'typeorm';
import { BaseEntity } from '../base.entity';

export enum CouponDiscountType {
  FIXED = 'FIXED',
  PERCENTAGE = 'PERCENTAGE',
}

@Entity({ name: 'coupons' })
@Index(['code'], { unique: true })
@Index(['isActive', 'startsAt', 'endsAt'])
export class Coupon extends BaseEntity {
  @Column({ type: 'varchar', length: 50 })
  code!: string;

  @Column({ name: 'discount_type', type: 'enum', enum: CouponDiscountType })
  discountType!: CouponDiscountType;

  @Column({ name: 'discount_value', type: 'decimal', precision: 12, scale: 2 })
  discountValue!: string;

  @Column({ name: 'minimum_amount', type: 'decimal', precision: 12, scale: 2, nullable: true })
  minimumAmount?: string | null;

  @Column({ name: 'maximum_discount', type: 'decimal', precision: 12, scale: 2, nullable: true })
  maximumDiscount?: string | null;

  @Column({ name: 'starts_at', type: 'timestamptz', nullable: true })
  startsAt?: Date | null;

  @Column({ name: 'ends_at', type: 'timestamptz', nullable: true })
  endsAt?: Date | null;

  @Column({ name: 'usage_limit', type: 'integer', nullable: true })
  usageLimit?: number | null;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive!: boolean;
}
