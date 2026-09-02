import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AuthUser?> login({
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.login(
      LoginRequestModel(email: email, password: password),
    );
    return response?.user;
  }

  @override
  Future<AuthUser?> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await _remoteDataSource.register(
      RegisterRequestModel(
        displayName: displayName,
        email: email,
        password: password,
      ),
    );
    return response?.user;
  }

  @override
  Future<void> logout() => _remoteDataSource.logout();
}
