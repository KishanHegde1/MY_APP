import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../base.entity';
import { Property } from '../property.entity';

@Entity({ name: 'rooms' })
@Index(['property', 'isAvailable'])
export class Room extends BaseEntity {
  @ManyToOne(() => Property, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'property_id' })
  property!: Property;

  @Column({ type: 'varchar', length: 150 })
  name!: string;

  @Column({ type: 'text', nullable: true })
  description?: string | null;

  @Column({ name: 'monthly_rent', type: 'decimal', precision: 12, scale: 2 })
  monthlyRent!: string;

  @Column({ name: 'max_occupancy', type: 'smallint', default: 1 })
  maxOccupancy!: number;

  @Column({ name: 'is_available', type: 'boolean', default: true })
  isAvailable!: boolean;
}
