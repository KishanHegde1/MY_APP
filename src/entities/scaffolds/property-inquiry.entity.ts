import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../base.entity';
import { Property } from '../property.entity';
import { User } from '../user.entity';

export enum PropertyInquiryStatus {
  OPEN = 'OPEN',
  RESPONDED = 'RESPONDED',
  CLOSED = 'CLOSED',
}

@Entity({ name: 'property_inquiries' })
@Index(['property', 'status'])
@Index(['requester', 'createdAt'])
export class PropertyInquiry extends BaseEntity {
  @ManyToOne(() => Property, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'property_id' })
  property!: Property;

  @ManyToOne(() => User, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'requester_id' })
  requester!: User;

  @Column({ type: 'text' })
  message!: string;

  @Column({
    type: 'enum',
    enum: PropertyInquiryStatus,
    default: PropertyInquiryStatus.OPEN,
  })
  status!: PropertyInquiryStatus;
}
