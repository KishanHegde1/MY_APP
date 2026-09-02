import { Column, Entity, Index, OneToMany } from 'typeorm';
import { UserStatus } from '../common/enums/user-status.enum';
import { BaseEntity } from './base.entity';
import { UserRole } from './user-role.entity';

@Entity({ name: 'users' })
@Index(['email'], { unique: true, where: '"deleted_at" IS NULL' })
@Index(['phoneNumber'], { unique: true, where: '"deleted_at" IS NULL' })
@Index(['firebaseUid'], {
  unique: true,
  where: '"firebase_uid" IS NOT NULL',
})
export class User extends BaseEntity {
  @Column({
    name: 'firebase_uid',
    type: 'varchar',
    length: 128,
    nullable: true,
  })
  firebaseUid?: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  email?: string | null;

  @Column({ name: 'phone_number', type: 'varchar', length: 32, nullable: true })
  phoneNumber?: string | null;

  @Column({ name: 'first_name', type: 'varchar', length: 100, nullable: true })
  firstName?: string | null;

  @Column({ name: 'last_name', type: 'varchar', length: 100, nullable: true })
  lastName?: string | null;

  @Column({
    name: 'password_hash',
    type: 'varchar',
    length: 255,
    nullable: true,
    select: false,
  })
  passwordHash?: string | null;

  @Column({ type: 'enum', enum: UserStatus, default: UserStatus.PENDING })
  status!: UserStatus;

  @Column({ name: 'is_phone_verified', type: 'boolean', default: false })
  isPhoneVerified!: boolean;

  @OneToMany(() => UserRole, (userRole) => userRole.user, { cascade: true })
  roles!: UserRole[];
}
