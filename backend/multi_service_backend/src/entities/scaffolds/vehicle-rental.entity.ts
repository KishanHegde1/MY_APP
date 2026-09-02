import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { BookingStatus } from '../../common/enums/booking-status.enum';
import { BaseEntity } from '../base.entity';
import { User } from '../user.entity';
import { Vehicle } from '../vehicle.entity';

@Entity({ name: 'vehicle_rentals' })
@Index(['customer', 'status'])
@Index(['vehicle', 'startsAt', 'endsAt'])
export class VehicleRental extends BaseEntity {
  @ManyToOne(() => User, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'customer_id' })
  customer!: User;

  @ManyToOne(() => Vehicle, { nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'vehicle_id' })
  vehicle!: Vehicle;

  @Column({ name: 'starts_at', type: 'timestamptz' })
  startsAt!: Date;

  @Column({ name: 'ends_at', type: 'timestamptz' })
  endsAt!: Date;

  @Column({ name: 'total_amount', type: 'decimal', precision: 12, scale: 2, nullable: true })
  totalAmount?: string | null;

  @Column({ type: 'enum', enum: BookingStatus, default: BookingStatus.PENDING })
  status!: BookingStatus;
}
