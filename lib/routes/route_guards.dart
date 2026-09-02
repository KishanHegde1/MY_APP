import 'app_routes.dart';

abstract final class AppRoles {
  static const customer = 'CUSTOMER';
  static const driver = 'DRIVER';
  static const vehicleOwner = 'VEHICLE_OWNER';
  static const propertyOwner = 'PROPERTY_OWNER';
  static const serviceProvider = 'SERVICE_PROVIDER';
  static const admin = 'ADMIN';
  static const supportStaff = 'SUPPORT_STAFF';
}

final class RouteGuardPolicy {
  const RouteGuardPolicy({
    this.requiresAuthentication = true,
    this.allowedRoles = const <String>{},
  });

  final bool requiresAuthentication;
  final Set<String> allowedRoles;
}

final class RouteGuardDecision {
  const RouteGuardDecision.allow() : redirectRoute = null;
  const RouteGuardDecision.redirect(this.redirectRoute);

  final String? redirectRoute;
  bool get isAllowed => redirectRoute == null;
}

typedef AuthenticationResolver = bool Function();
typedef RoleResolver = Set<String> Function();

final class RouteGuards {
  RouteGuards({
    required this.isAuthenticated,
    required this.roles,
    this.unauthenticatedRoute = AppRoutes.login,
    this.unauthorizedRoute = AppRoutes.home,
  });

  final AuthenticationResolver isAuthenticated;
  final RoleResolver roles;
  final String unauthenticatedRoute;
  final String unauthorizedRoute;

  RouteGuardDecision evaluate(RouteGuardPolicy policy) {
    if (policy.requiresAuthentication && !isAuthenticated()) {
      return RouteGuardDecision.redirect(unauthenticatedRoute);
    }

    if (policy.allowedRoles.isNotEmpty &&
        roles().intersection(policy.allowedRoles).isEmpty) {
      return RouteGuardDecision.redirect(unauthorizedRoute);
    }

    return const RouteGuardDecision.allow();
  }
}
