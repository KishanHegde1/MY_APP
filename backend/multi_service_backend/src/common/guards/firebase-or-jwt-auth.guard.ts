import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { isUUID } from 'class-validator';
import { Request } from 'express';
import { UserRoleType } from '../enums/user-role.enum';
import { FirebaseIdentityService } from '../../integrations/firebase/firebase-identity.service';
import { JwtPayload } from '../../modules/auth/interfaces/jwt-payload.interface';

type AuthenticatedRequest = Request & { user?: JwtPayload };

@Injectable()
export class FirebaseOrJwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    private readonly firebaseIdentityService: FirebaseIdentityService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const token = bearerToken(request.headers.authorization);
    if (token == null) {
      throw new UnauthorizedException('Authentication is required.');
    }

    const backendPayload = await this.verifyBackendToken(token);
    request.user =
      backendPayload ??
      (await this.firebaseIdentityService.authenticate(token));
    return true;
  }

  private async verifyBackendToken(token: string): Promise<JwtPayload | null> {
    try {
      const decoded = await this.jwtService.verifyAsync<Record<string, unknown>>(
        token,
      );
      if (typeof decoded !== 'object' || decoded == null) return null;
      const candidate = decoded as { sub?: unknown; roles?: unknown };
      if (typeof candidate.sub !== 'string' || !isUUID(candidate.sub)) {
        return null;
      }
      const allowedRoles = new Set<string>(Object.values(UserRoleType));
      const roles = Array.isArray(candidate.roles)
        ? candidate.roles.filter(
            (role): role is UserRoleType =>
              typeof role === 'string' && allowedRoles.has(role),
          )
        : [];
      return { sub: candidate.sub, roles };
    } catch {
      return null;
    }
  }
}

function bearerToken(value: string | undefined): string | null {
  const match = value?.match(/^Bearer\s+([^\s]+)$/i);
  return match?.[1] ?? null;
}
