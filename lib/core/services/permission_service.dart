enum AppPermission {
  location,
  camera,
  photos,
  notifications,
  storage,
  biometric,
}

enum AppPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unavailable,
}

abstract interface class PermissionService {
  Future<AppPermissionStatus> status(AppPermission permission);
  Future<AppPermissionStatus> request(AppPermission permission);
  Future<bool> openAppSettings();
}

final class PlaceholderPermissionService implements PermissionService {
  const PlaceholderPermissionService();

  @override
  Future<AppPermissionStatus> status(AppPermission permission) async =>
      AppPermissionStatus.unavailable;

  @override
  Future<AppPermissionStatus> request(AppPermission permission) async =>
      AppPermissionStatus.unavailable;

  @override
  Future<bool> openAppSettings() async => false;
}
