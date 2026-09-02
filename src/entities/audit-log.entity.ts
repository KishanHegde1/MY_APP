import { Column, Entity, Index, ManyToOne } from 'typeorm';
import { BaseEntity } from './base.entity'; import { User } from './user.entity';
@Entity({ name: 'audit_logs' }) @Index(['actor', 'createdAt'])
export class AuditLog extends BaseEntity { @ManyToOne(() => User, { nullable: true, onDelete: 'SET NULL' }) actor?: User | null; @Column({ type: 'varchar', length: 100 }) action!: string; @Column({ type: 'varchar', length: 100 }) resource!: string; @Column({ name: 'metadata', type: 'jsonb', nullable: true }) metadata?: Record<string, unknown> | null; }
