import 'network_info.dart';

final class ConnectivityService implements NetworkInfo {
  ConnectivityService({bool initiallyConnected = true})
    : _connected = initiallyConnected;

  bool _connected;
  final Stream<bool> _emptyChanges = const Stream<bool>.empty();

  @override
  Future<bool> get isConnected async => _connected;

  @override
  Stream<bool> get connectivityChanges => _emptyChanges;

  void updateForTesting(bool connected) => _connected = connected;
}
