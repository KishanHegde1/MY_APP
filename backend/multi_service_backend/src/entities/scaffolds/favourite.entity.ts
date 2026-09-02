import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../base.entity';
import { User } from '../user.entity';

export enum FavouriteTargetType {
  VEHICLE = 'VEHICLE',
  ROOM = 'ROOM',
  PROPERTY = 'PROPERTY',
  PROVIDER = 'PROVIDER',
}

@Entity({ name: 'favourites' })
@Index(['user', 'targetType', 'targetId'], { unique: true })
export class Favourite extends BaseEntity {
  @ManyToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ name: 'target_type', type: 'enum', enum: FavouriteTargetType })
  targetType!: FavouriteTargetType;

  @Column({ name: 'target_id', type: 'uuid' })
  targetId!: string;
}
