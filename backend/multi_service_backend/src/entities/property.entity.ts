import { Column, Entity, Index, ManyToOne } from 'typeorm';
import { BaseEntity } from './base.entity'; import { User } from './user.entity';
@Entity({ name: 'properties' }) @Index(['owner', 'type'])
export class Property extends BaseEntity { @ManyToOne(() => User, { nullable: false, onDelete: 'RESTRICT' }) owner!: User; @Column({ type: 'varchar', length: 50 }) type!: string; @Column({ type: 'varchar', length: 255 }) title!: string; @Column({ name: 'monthly_rent', type: 'decimal', precision: 12, scale: 2, nullable: true }) monthlyRent?: string | null; @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true }) latitude?: string | null; @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true }) longitude?: string | null; }
