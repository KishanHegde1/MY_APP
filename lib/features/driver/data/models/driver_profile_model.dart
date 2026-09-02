class DriverProfileModel {
  const DriverProfileModel({
    required this.id,
    required this.displayName,
    required this.isVerified,
    required this.isAvailable,
  });

  final String id;
  final String displayName;
  final bool isVerified;
  final bool isAvailable;
}
