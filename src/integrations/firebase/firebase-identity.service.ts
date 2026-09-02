import {
  ConflictException,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DecodedIdToken } from 'firebase-admin/auth';
import { FindOptionsWhere, Repository } from 'typeorm';
import { UserRoleType } from '../../common/enums/user-role.enum';
import { UserStatus } from '../../common/enums/user-status.enum';
import { User } from '../../entities/user.entity';
import { UserRole } from '../../entities/user-role.entity';
import { JwtPayload } from '../../modules/auth/interfaces/jwt-payload.interface';
import { FirebaseAdminTokenVerifier } from './firebase-admin-token-verifier.service';

@Injectable()
export class FirebaseIdentityService {
  constructor(
    private readonly tokenVerifier: FirebaseAdminTokenVerifier,
    @InjectRepository(User)
    private readonly users: Repository<User>,
    @InjectRepository(UserRole)
    private readonly userRoles: Repository<UserRole>,
  ) {}

  async authenticate(idToken: string): Promise<JwtPayload> {
    const decoded = await this.tokenVerifier.verify(idToken);
    if (!decoded.uid || decoded.uid.length > 128) {
      throw new UnauthorizedException('Invalid Firebase identity.');
    }

    let user = await this.findByFirebaseUid(decoded.uid);
    if (user == null) user = await this.linkOrCreateUser(decoded);
    this.assertActive(user);
    const roles = await this.ensureCustomerRole(user);
    return { sub: user.id, roles };
  }

  private findByFirebaseUid(firebaseUid: string): Promise<User | null> {
    return this.users.findOne({
      where: { firebaseUid },
      relations: { roles: true },
    });
  }

  private async linkOrCreateUser(decoded: DecodedIdToken): Promise<User> {
    const email = decoded.email_verified
      ? decoded.email?.trim().toLowerCase()
      : undefined;
    const phoneNumber = decoded.phone_number?.trim();
    const identityMatches: FindOptionsWhere<User>[] = [];
    if (email) identityMatches.push({ email });
    if (phoneNumber) identityMatches.push({ phoneNumber });

    const existing = identityMatches.length
      ? await this.users.findOne({
          where: identityMatches,
          relations: { roles: true },
        })
      : null;
    if (existing != null) {
      if (existing.firebaseUid && existing.firebaseUid !== decoded.uid) {
        throw new ConflictException(
          'This account is already linked to another Firebase identity.',
        );
      }
      this.assertActive(existing);
      existing.firebaseUid = decoded.uid;
      if (existing.status === UserStatus.PENDING) {
        existing.status = UserStatus.ACTIVE;
      }
      return this.saveIdentity(existing, decoded.uid);
    }

    const name = splitName(
      typeof decoded.name === 'string' ? decoded.name : undefined,
    );
    const created = this.users.create({
      firebaseUid: decoded.uid,
      email: email ?? null,
      phoneNumber: phoneNumber ?? null,
      firstName: name.firstName,
      lastName: name.lastName,
      status: UserStatus.ACTIVE,
      isPhoneVerified: phoneNumber != null,
    });
    return this.saveIdentity(created, decoded.uid);
  }

  private async saveIdentity(user: User, firebaseUid: string): Promise<User> {
    try {
      return await this.users.save(user);
    } catch (error) {
      if (!isUniqueViolation(error)) throw error;
      const concurrent = await this.findByFirebaseUid(firebaseUid);
      if (concurrent != null) return concurrent;
      throw new ConflictException(
        'This Firebase identity could not be linked to the account.',
      );
    }
  }

  private assertActive(user: User): void {
    if (
      user.status === UserStatus.SUSPENDED ||
      user.status === UserStatus.DEACTIVATED
    ) {
      throw new ForbiddenException('This account is not active.');
    }
  }

  private async ensureCustomerRole(user: User): Promise<UserRoleType[]> {
    const roles = new Set((user.roles ?? []).map((item) => item.role));
    if (!roles.has(UserRoleType.CUSTOMER)) {
      const existing = await this.userRoles.findOne({
        where: { user: { id: user.id }, role: UserRoleType.CUSTOMER },
      });
      if (existing == null) {
        try {
          await this.userRoles.save(
            this.userRoles.create({
              user,
              role: UserRoleType.CUSTOMER,
            }),
          );
        } catch (error) {
          if (!isUniqueViolation(error)) throw error;
        }
      }
      roles.add(UserRoleType.CUSTOMER);
    }
    return [...roles];
  }
}

function splitName(value: string | undefined): {
  firstName: string | null;
  lastName: string | null;
} {
  const parts = value?.trim().split(/\s+/).filter(Boolean) ?? [];
  if (parts.length === 0) return { firstName: null, lastName: null };
  return {
    firstName: parts[0].slice(0, 100),
    lastName:
      parts.length > 1 ? parts.slice(1).join(' ').slice(0, 100) : null,
  };
}

function isUniqueViolation(error: unknown): boolean {
  if (typeof error !== 'object' || error == null || !('code' in error)) {
    return false;
  }
  return (error as { code?: unknown }).code === '23505';
}
