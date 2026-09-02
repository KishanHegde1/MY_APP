import { Column, Entity, Index, JoinColumn, ManyToOne } from 'typeorm';
import { UserRoleType } from '../common/enums/user-role.enum';
import { BaseEntity } from './base.entity';
import { User } from './user.entity';

@Entity({ name: 'user_roles' })
@Index(['user', 'role'], { unique: true })
export class UserRole extends BaseEntity {
  @ManyToOne(() => User, (user) => user.roles, {
    onDelete: 'CASCADE',
    nullable: false,
  })
  @JoinColumn({ name: 'user_id' })
  user!: User;

  @Column({ type: 'enum', enum: UserRoleType })
  role!: UserRoleType;
}
