import { SetMetadata } from '@nestjs/common';
import { UserRoleType } from '../enums/user-role.enum';
export const ROLES_KEY = 'roles';
export const Roles = (...roles: UserRoleType[]) => SetMetadata(ROLES_KEY, roles);
