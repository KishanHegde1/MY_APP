import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../base.entity';
import { User } from '../user.entity';
import { ChatRoom } from './chat-room.entity';

@Entity({ name: 'chat_messages' })
@Index(['chatRoom', 'createdAt'])
export class ChatMessage extends BaseEntity {
  @ManyToOne(() => ChatRoom, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'chat_room_id' })
  chatRoom!: ChatRoom;

  @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'sender_id' })
  sender?: User | null;

  @Column({ type: 'text' })
  body!: string;

  @Column({ name: 'read_at', type: 'timestamptz', nullable: true })
  readAt?: Date | null;
}
