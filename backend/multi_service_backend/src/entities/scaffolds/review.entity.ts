import { Check, Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../base.entity';
import { Booking } from '../booking.entity';
import { User } from '../user.entity';

@Entity({ name: 'reviews' })
@Check('"rating" BETWEEN 1 AND 5')
@Index(['booking', 'author'], { unique: true })
@Index(['subjectUser', 'createdAt'])
export class Review extends BaseEntity {
  @ManyToOne(() => Booking, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'booking_id' })
  booking!: Booking;

  @ManyToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'author_id' })
  author!: User;

  @ManyToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'subject_user_id' })
  subjectUser!: User;

  @Column({ type: 'smallint' })
  rating!: number;

  @Column({ type: 'text', nullable: true })
  comment?: string | null;
}
