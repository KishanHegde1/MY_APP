/// Authenticated account data exposed to the presentation layer.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.roles = const <String>[],
  });

  final String id;
  final String displayName;
  final String email;
  final List<String> roles;
}
