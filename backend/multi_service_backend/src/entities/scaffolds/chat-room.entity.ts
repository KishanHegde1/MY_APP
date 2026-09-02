import {
  Entity,
  Index,
  JoinColumn,
  JoinTable,
  ManyToMany,
  ManyToOne,
} from 'typeorm';
import { BaseEntity } from '../base.entity';
import { Booking } from '../booking.entity';
import { User } from '../user.entity';

@Entity({ name: 'chat_rooms' })
@Index(['booking'])
export class ChatRoom extends BaseEntity {
  @ManyToOne(() => Booking, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'booking_id' })
  booking?: Booking | null;

  @ManyToMany(() => User)
  @JoinTable({
    name: 'chat_room_participants',
    joinColumn: { name: 'chat_room_id', referencedColumnName: 'id' },
    inverseJoinColumn: { name: 'user_id', referencedColumnName: 'id' },
  })
  participants!: User[];
}
