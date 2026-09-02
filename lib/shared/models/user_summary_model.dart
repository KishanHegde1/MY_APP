final class UserSummaryModel {
  const UserSummaryModel({
    required this.id,
    required this.displayName,
    this.avatarUrl,
    this.roles = const <String>{},
    this.isVerified = false,
  });

  factory UserSummaryModel.fromJson(Map<String, Object?> json) {
    return UserSummaryModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      roles: switch (json['roles']) {
        final List<Object?> values =>
          values.map((value) => value.toString()).toSet(),
        _ => const <String>{},
      },
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  final String id;
  final String displayName;
  final String? avatarUrl;
  final Set<String> roles;
  final bool isVerified;

  bool hasRole(String role) => roles.contains(role);
}
