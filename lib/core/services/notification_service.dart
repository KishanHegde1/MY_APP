typedef NotificationTapHandler = void Function(Map<String, Object?> payload);

abstract interface class NotificationService {
  Future<void> initialize({NotificationTapHandler? onNotificationTap});
  Future<String?> deviceToken();
  Future<void> clearToken();
}

final class PlaceholderNotificationService implements NotificationService {
  const PlaceholderNotificationService();

  @override
  Future<void> initialize({NotificationTapHandler? onNotificationTap}) async {}

  @override
  Future<String?> deviceToken() async => null;

  @override
  Future<void> clearToken() async {}
}
