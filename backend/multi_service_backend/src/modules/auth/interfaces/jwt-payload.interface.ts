import { UserRoleType } from '../../../common/enums/user-role.enum';
export interface JwtPayload { sub: string; roles: UserRoleType[]; }
