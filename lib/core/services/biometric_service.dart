abstract interface class BiometricService {
  Future<bool> isAvailable();
  Future<bool> authenticate({required String reason});
}

final class PlaceholderBiometricService implements BiometricService {
  const PlaceholderBiometricService();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate({required String reason}) async => false;
}
