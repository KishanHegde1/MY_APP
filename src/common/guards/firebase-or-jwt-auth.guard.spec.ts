import {
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRoleType } from '../enums/user-role.enum';
import { FirebaseIdentityService } from '../../integrations/firebase/firebase-identity.service';
import { JwtPayload } from '../../modules/auth/interfaces/jwt-payload.interface';
import { FirebaseOrJwtAuthGuard } from './firebase-or-jwt-auth.guard';

const userId = '2a9aeac8-4aa8-4c4c-9b42-7d7289ad4bcb';

describe('FirebaseOrJwtAuthGuard', () => {
  const verifyAsync = jest.fn();
  const authenticate = jest.fn();
  const guard = new FirebaseOrJwtAuthGuard(
    { verifyAsync } as unknown as JwtService,
    { authenticate } as unknown as FirebaseIdentityService,
  );

  beforeEach(() => jest.resetAllMocks());

  it('accepts a valid backend JWT without invoking Firebase', async () => {
    verifyAsync.mockResolvedValue({
      sub: userId,
      roles: [UserRoleType.CUSTOMER, 'UNTRUSTED_ROLE'],
    });
    const { context, request } = requestContext('Bearer backend-jwt');

    await expect(guard.canActivate(context)).resolves.toBe(true);

    expect(request.user).toEqual({
      sub: userId,
      roles: [UserRoleType.CUSTOMER],
    });
    expect(authenticate).not.toHaveBeenCalled();
  });

  it('verifies a Firebase ID token and uses its mapped Neon user id', async () => {
    verifyAsync.mockRejectedValue(new Error('not a backend JWT'));
    authenticate.mockResolvedValue({
      sub: userId,
      roles: [UserRoleType.CUSTOMER],
    });
    const { context, request } = requestContext('Bearer firebase-id-token');

    await expect(guard.canActivate(context)).resolves.toBe(true);

    expect(authenticate).toHaveBeenCalledWith('firebase-id-token');
    expect(request.user?.sub).toBe(userId);
  });

  it('does not accept a raw Firebase UID as authentication', async () => {
    verifyAsync.mockRejectedValue(new Error('not a JWT'));
    authenticate.mockRejectedValue(
      new UnauthorizedException('Invalid or expired authentication token.'),
    );
    const { context } = requestContext('Bearer raw-firebase-uid');

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('requires a strict Bearer header', async () => {
    const { context } = requestContext(undefined);

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(verifyAsync).not.toHaveBeenCalled();
    expect(authenticate).not.toHaveBeenCalled();
  });
});

function requestContext(authorization: string | undefined): {
  context: ExecutionContext;
  request: { headers: { authorization?: string }; user?: JwtPayload };
} {
  const request = { headers: { authorization } };
  const context = {
    switchToHttp: () => ({ getRequest: () => request }),
  } as ExecutionContext;
  return { context, request };
}
