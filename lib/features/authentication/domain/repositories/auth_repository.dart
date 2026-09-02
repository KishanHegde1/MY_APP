import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser?> login({required String email, required String password});

  Future<AuthUser?> register({
    required String displayName,
    required String email,
    required String password,
  });

  Future<void> logout();
}
