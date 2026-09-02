import { DecodedIdToken } from 'firebase-admin/auth';
import { Repository } from 'typeorm';
import { UserRoleType } from '../../common/enums/user-role.enum';
import { UserStatus } from '../../common/enums/user-status.enum';
import { User } from '../../entities/user.entity';
import { UserRole } from '../../entities/user-role.entity';
import { FirebaseAdminTokenVerifier } from './firebase-admin-token-verifier.service';
import { FirebaseIdentityService } from './firebase-identity.service';

const userId = '2a9aeac8-4aa8-4c4c-9b42-7d7289ad4bcb';

describe('FirebaseIdentityService', () => {
  const verify = jest.fn<Promise<DecodedIdToken>, [string]>();
  const findUser = jest.fn<Promise<User | null>, [unknown]>();
  const createUser = jest.fn<User, [Partial<User>]>();
  const saveUser = jest.fn<Promise<User>, [User]>();
  const findRole = jest.fn<Promise<UserRole | null>, [unknown]>();
  const createRole = jest.fn<UserRole, [Partial<UserRole>]>();
  const saveRole = jest.fn<Promise<UserRole>, [UserRole]>();
  const users = {
    findOne: findUser,
    create: createUser,
    save: saveUser,
  } as unknown as Repository<User>;
  const roles = {
    findOne: findRole,
    create: createRole,
    save: saveRole,
  } as unknown as Repository<UserRole>;
  const service = new FirebaseIdentityService(
    { verify } as unknown as FirebaseAdminTokenVerifier,
    users,
    roles,
  );

  beforeEach(() => {
    jest.resetAllMocks();
    createUser.mockImplementation((value) => value as User);
    createRole.mockImplementation((value) => value as UserRole);
  });

  it('maps a verified Firebase UID to an existing Neon user', async () => {
    verify.mockResolvedValue(firebaseToken());
    findUser.mockResolvedValue({
      id: userId,
      firebaseUid: 'firebase-user-123',
      status: UserStatus.ACTIVE,
      roles: [{ role: UserRoleType.CUSTOMER } as UserRole],
    } as User);

    await expect(service.authenticate('verified-id-token')).resolves.toEqual({
      sub: userId,
      roles: [UserRoleType.CUSTOMER],
    });

    expect(verify).toHaveBeenCalledWith('verified-id-token');
    expect(saveUser).not.toHaveBeenCalled();
  });

  it('provisions a Neon customer only from verified Firebase claims', async () => {
    verify.mockResolvedValue(
      firebaseToken({
        email: 'Kishan@example.com',
        email_verified: true,
        name: 'Kishan Hegde',
      }),
    );
    findUser.mockResolvedValueOnce(null).mockResolvedValueOnce(null);
    saveUser.mockImplementation((value: User) =>
      Promise.resolve({ ...value, id: userId, roles: [] } as User),
    );
    findRole.mockResolvedValue(null);
    saveRole.mockResolvedValue({} as UserRole);

    await expect(service.authenticate('verified-id-token')).resolves.toEqual({
      sub: userId,
      roles: [UserRoleType.CUSTOMER],
    });

    expect(createUser).toHaveBeenCalledWith({
      firebaseUid: 'firebase-user-123',
      email: 'kishan@example.com',
      phoneNumber: null,
      firstName: 'Kishan',
      lastName: 'Hegde',
      status: UserStatus.ACTIVE,
      isPhoneVerified: false,
    });
    const createdRole = createRole.mock.calls[0][0];
    expect(createdRole.user?.id).toBe(userId);
    expect(createdRole.role).toBe(UserRoleType.CUSTOMER);
  });

  it('does not link accounts by an unverified email claim', async () => {
    verify.mockResolvedValue(
      firebaseToken({
        email: 'unverified@example.com',
        email_verified: false,
      }),
    );
    findUser.mockResolvedValueOnce(null);
    saveUser.mockImplementation((value: User) =>
      Promise.resolve({
        ...value,
        id: userId,
        roles: [{ role: UserRoleType.CUSTOMER } as UserRole],
      }),
    );

    await service.authenticate('verified-id-token');

    expect(findUser).toHaveBeenCalledTimes(1);
    expect(createUser).toHaveBeenCalledWith(
      expect.objectContaining({ email: null }),
    );
  });
});

function firebaseToken(
  overrides: Partial<DecodedIdToken> = {},
): DecodedIdToken {
  return {
    aud: 'multi-service-1f99d',
    auth_time: 0,
    exp: 4_102_444_800,
    firebase: { identities: {}, sign_in_provider: 'password' },
    iat: 0,
    iss: 'https://securetoken.google.com/multi-service-1f99d',
    sub: 'firebase-user-123',
    uid: 'firebase-user-123',
    ...overrides,
  };
}
