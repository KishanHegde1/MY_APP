import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import '../widgets/guest_profile_hero.dart';
import '../widgets/profile_action_grid.dart';
import '../widgets/profile_sync_card.dart';
import '../widgets/signed_in_profile_hero.dart';
import '../widgets/theme_appearance_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 840;
            final horizontalPadding = constraints.maxWidth >= 1100
                ? 32.0
                : 20.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                20,
                horizontalPadding,
                36,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PageHeading(isWide: isWide),
                      const SizedBox(height: 22),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _FirebaseProfileHero(
                                    onSignIn: () =>
                                        context.push(AppRoutes.login),
                                  ),
                                  const SizedBox(height: 24),
                                  _ActivityActions(
                                    onBookings: () =>
                                        context.go(AppRoutes.bookings),
                                    onFavourites: () =>
                                        context.go(AppRoutes.favourites),
                                    onNotifications: () =>
                                        context.go(AppRoutes.notifications),
                                  ),
                                  const SizedBox(height: 24),
                                  _PartnerActions(
                                    onDriver: () =>
                                        context.push(AppRoutes.driverDashboard),
                                    onProvider: () => context.push(
                                      AppRoutes.providerDashboard,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),
                            const SizedBox(
                              width: 342,
                              child: Column(
                                children: [
                                  ThemeAppearanceCard(),
                                  SizedBox(height: 18),
                                  ProfileSyncCard(),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _FirebaseProfileHero(
                          onSignIn: () => context.push(AppRoutes.login),
                        ),
                        const SizedBox(height: 20),
                        const ThemeAppearanceCard(),
                        const SizedBox(height: 24),
                        _ActivityActions(
                          onBookings: () => context.go(AppRoutes.bookings),
                          onFavourites: () => context.go(AppRoutes.favourites),
                          onNotifications: () =>
                              context.go(AppRoutes.notifications),
                        ),
                        const SizedBox(height: 24),
                        _PartnerActions(
                          onDriver: () =>
                              context.push(AppRoutes.driverDashboard),
                          onProvider: () =>
                              context.push(AppRoutes.providerDashboard),
                        ),
                        const SizedBox(height: 20),
                        const ProfileSyncCard(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FirebaseProfileHero extends StatelessWidget {
  const _FirebaseProfileHero({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    if (Firebase.apps.isEmpty) {
      return GuestProfileHero(onSignIn: onSignIn);
    }

    final auth = FirebaseAuth.instance;
    return StreamBuilder<User?>(
      initialData: auth.currentUser,
      stream: auth.userChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          return GuestProfileHero(onSignIn: onSignIn);
        }

        return SignedInProfileHero(
          user: user,
          onUpdateProfile: () => context.push(AppRoutes.editProfile),
          onSignOut: () => _signOut(context),
        );
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('You have been signed out.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not sign out. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your space',
                style:
                    (isWide
                            ? theme.textTheme.headlineMedium
                            : theme.textTheme.headlineSmall)
                        ?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.8,
                        ),
              ),
              const SizedBox(height: 5),
              Text(
                'Personalise the app and find everything in one place.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        if (isWide)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_outlined, size: 17, color: Color(0xFF14B8A6)),
                SizedBox(width: 7),
                Text(
                  'Privacy first',
                  style: TextStyle(
                    color: Color(0xFF14B8A6),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActivityActions extends StatelessWidget {
  const _ActivityActions({
    required this.onBookings,
    required this.onFavourites,
    required this.onNotifications,
  });

  final VoidCallback onBookings;
  final VoidCallback onFavourites;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return ProfileActionSection(
      title: 'Your activity',
      description: 'Quick access to the things that matter to you.',
      actions: [
        ProfileAction(
          title: 'Bookings',
          description: 'Trips, stays and rentals',
          icon: Icons.receipt_long_rounded,
          accent: const Color(0xFF2563EB),
          onTap: onBookings,
        ),
        ProfileAction(
          title: 'Favourites',
          description: 'Services you save for later',
          icon: Icons.favorite_rounded,
          accent: const Color(0xFFEA4C89),
          onTap: onFavourites,
        ),
        ProfileAction(
          title: 'Notifications',
          description: 'Updates and useful alerts',
          icon: Icons.notifications_rounded,
          accent: const Color(0xFFF59E0B),
          onTap: onNotifications,
        ),
      ],
    );
  }
}

class _PartnerActions extends StatelessWidget {
  const _PartnerActions({required this.onDriver, required this.onProvider});

  final VoidCallback onDriver;
  final VoidCallback onProvider;

  @override
  Widget build(BuildContext context) {
    return ProfileActionSection(
      title: 'Work with Multi Service',
      description: 'Explore a workspace for your future role.',
      actions: [
        ProfileAction(
          title: 'Driver workspace',
          description: 'Driver onboarding and jobs',
          icon: Icons.local_taxi_rounded,
          accent: const Color(0xFF14B8A6),
          onTap: onDriver,
        ),
        ProfileAction(
          title: 'Provider workspace',
          description: 'Manage future service listings',
          icon: Icons.storefront_rounded,
          accent: const Color(0xFF7C3AED),
          onTap: onProvider,
        ),
      ],
    );
  }
}
