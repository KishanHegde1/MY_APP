class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    required this.email,
  });

  final String id;
  final String displayName;
  final String? phoneNumber;
  final String? email;
}
