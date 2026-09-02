import {
  Column,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
} from 'typeorm';
import { BaseEntity } from './base.entity';
import { User } from './user.entity';

export enum PickupLocationSource {
  GPS = 'GPS',
  MANUAL = 'MANUAL',
  PIN = 'PIN',
}

@Entity({ name: 'user_pickup_locations' })
@Index(['userId'], { unique: true })
export class UserPickupLocation extends BaseEntity {
  @Column({ name: 'user_id', type: 'uuid' })
  userId!: string;

  @ManyToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ type: 'decimal', precision: 10, scale: 7 })
  latitude!: string;

  @Column({ type: 'decimal', precision: 10, scale: 7 })
  longitude!: string;

  @Column({ name: 'formatted_address', type: 'varchar', length: 500 })
  formattedAddress!: string;

  @Column({
    type: 'enum',
    enum: PickupLocationSource,
    enumName: 'pickup_location_source_enum',
  })
  source!: PickupLocationSource;
}
