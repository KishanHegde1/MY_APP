import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/authentication/presentation/screens/complete_profile_screen.dart';
import '../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../features/authentication/presentation/screens/login_screen.dart';
import '../features/authentication/presentation/screens/otp_screen.dart';
import '../features/authentication/presentation/screens/register_screen.dart';
import '../features/bookings/presentation/screens/my_bookings_screen.dart';
import '../features/driver/presentation/screens/driver_dashboard_screen.dart';
import '../features/favourites/presentation/screens/favourites_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/local_rides/presentation/screens/local_ride_home_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/outstation_rides/presentation/screens/outstation_home_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/property_rentals/presentation/screens/property_home_screen.dart';
import '../features/provider_portal/presentation/screens/provider_dashboard_screen.dart';
import '../features/room_rentals/presentation/screens/room_rental_home_screen.dart';
import '../features/splash/presentation/screens/splash_screen.dart';
import '../features/vehicle_rentals/presentation/screens/vehicle_rental_home_screen.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: (context, state) {
    // TODO: connect RouteGuards after real authentication/session restoration exists.
    return null;
  },
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, _) => const OnboardingScreen(),
    ),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginScreen()),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (_, _) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (_, _) => const RegisterScreen(),
    ),
    GoRoute(path: AppRoutes.otp, builder: (_, _) => const OtpScreen()),
    GoRoute(
      path: AppRoutes.completeProfile,
      builder: (_, _) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.localRides,
      builder: (_, _) => const LocalRideHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.outstationRides,
      builder: (_, _) => const OutstationHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.vehicleRentals,
      builder: (_, _) => const VehicleRentalHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.roomRentals,
      builder: (_, _) => const RoomRentalHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.propertyRentals,
      builder: (_, _) => const PropertyHomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.driverDashboard,
      builder: (_, _) => const DriverDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.providerDashboard,
      builder: (_, _) => const ProviderDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.editProfile,
      builder: (_, _) => const EditProfileScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _MainNavigationShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => HomeScreen(
                onServiceSelected: (service) => context.push('/$service'),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.bookings,
              builder: (_, _) => const MyBookingsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.favourites,
              builder: (_, _) => const FavouritesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.notifications,
              builder: (_, _) => const NotificationsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, _) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _MainNavigationShell extends StatelessWidget {
  const _MainNavigationShell({required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Favourites',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
