import '../models/auth_response_model.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';

/// API boundary for authentication. Real networking is intentionally deferred.
class AuthRemoteDataSource {
  const AuthRemoteDataSource();

  Future<AuthResponseModel?> login(LoginRequestModel request) async {
    // TODO: Send the login request through the shared API client.
    return null;
  }

  Future<AuthResponseModel?> register(RegisterRequestModel request) async {
    // TODO: Send the registration request through the shared API client.
    return null;
  }

  Future<void> logout() async {
    // TODO: Revoke the refresh token when the backend endpoint is available.
  }
}
