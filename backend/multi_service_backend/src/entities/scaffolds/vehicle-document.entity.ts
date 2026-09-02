import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BaseEntity } from '../base.entity';
import { Vehicle } from '../vehicle.entity';

export enum VehicleDocumentType {
  REGISTRATION = 'REGISTRATION',
  INSURANCE = 'INSURANCE',
  FITNESS_CERTIFICATE = 'FITNESS_CERTIFICATE',
  POLLUTION_CERTIFICATE = 'POLLUTION_CERTIFICATE',
}

@Entity({ name: 'vehicle_documents' })
@Index(['vehicle', 'documentType'])
@Index(['expiresAt'])
export class VehicleDocument extends BaseEntity {
  @ManyToOne(() => Vehicle, { nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'vehicle_id' })
  vehicle!: Vehicle;

  @Column({ name: 'document_type', type: 'enum', enum: VehicleDocumentType })
  documentType!: VehicleDocumentType;

  @Column({ name: 'storage_key', type: 'varchar', length: 512 })
  storageKey!: string;

  @Column({ name: 'expires_at', type: 'date', nullable: true })
  expiresAt?: string | null;

  @Column({ name: 'is_verified', type: 'boolean', default: false })
  isVerified!: boolean;
}
