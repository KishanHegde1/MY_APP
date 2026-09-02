import { Column, Entity, Index, ManyToOne } from 'typeorm';
import { BaseEntity } from './base.entity'; import { User } from './user.entity';
@Entity({ name: 'vehicles' }) @Index(['owner', 'registrationNumber'], { unique: true })
export class Vehicle extends BaseEntity { @ManyToOne(() => User, { nullable: false, onDelete: 'RESTRICT' }) owner!: User; @Column({ name: 'registration_number', type: 'varchar', length: 50 }) registrationNumber!: string; @Column({ type: 'varchar', length: 100 }) type!: string; @Column({ type: 'varchar', length: 100, nullable: true }) make?: string | null; @Column({ type: 'varchar', length: 100, nullable: true }) model?: string | null; }
