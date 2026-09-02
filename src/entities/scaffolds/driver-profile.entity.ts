import { Column, Entity, Index, JoinColumn, OneToOne } from 'typeorm';
import { BaseEntity } from '../base.entity';
import { User } from '../user.entity';

export enum DriverApprovalStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  SUSPENDED = 'SUSPENDED',
}

@Entity({ name: 'driver_profiles' })
@Index(['user'], { unique: true })
@Index(['approvalStatus', 'isAvailable'])
export class DriverProfile extends BaseEntity {
  @OneToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'license_number', type: 'varchar', length: 100, unique: true })
  licenseNumber!: string;

  @Column({
    name: 'approval_status',
    type: 'enum',
    enum: DriverApprovalStatus,
    default: DriverApprovalStatus.PENDING,
  })
  approvalStatus!: DriverApprovalStatus;

  @Column({ name: 'is_available', type: 'boolean', default: false })
  isAvailable!: boolean;

  @Column({ name: 'average_rating', type: 'decimal', precision: 3, scale: 2, default: 0 })
  averageRating!: string;
}
