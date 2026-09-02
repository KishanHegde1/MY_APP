import { Column, Entity, Index, JoinColumn, OneToOne } from 'typeorm';
import { BaseEntity } from '../base.entity';
import { User } from '../user.entity';

export enum ProviderApprovalStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  SUSPENDED = 'SUSPENDED',
}

@Entity({ name: 'provider_profiles' })
@Index(['user'], { unique: true })
@Index(['approvalStatus'])
export class ProviderProfile extends BaseEntity {
  @OneToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'business_name', type: 'varchar', length: 255, nullable: true })
  businessName?: string | null;

  @Column({
    name: 'approval_status',
    type: 'enum',
    enum: ProviderApprovalStatus,
    default: ProviderApprovalStatus.PENDING,
  })
  approvalStatus!: ProviderApprovalStatus;

  @Column({ name: 'tax_identifier', type: 'varchar', length: 100, nullable: true })
  taxIdentifier?: string | null;
}
