abstract interface class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get connectivityChanges;
}

final class AlwaysConnectedNetworkInfo implements NetworkInfo {
  const AlwaysConnectedNetworkInfo();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get connectivityChanges => const Stream<bool>.empty();
}
