import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';

class GuestProfileHero extends StatelessWidget {
  const GuestProfileHero({required this.onSignIn, super.key});

  final VoidCallback onSignIn;

  static const _navy = Color(0xFF132238);
  static const _blue = Color(0xFF2563EB);
  static const _teal = Color(0xFF14B8A6);
  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_navy, Color(0xFF1D3F67), _blue],
            stops: [0, 0.62, 1],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -68,
              top: -82,
              child: _Glow(size: 220, color: _teal.withValues(alpha: 0.16)),
            ),
            Positioned(
              left: -58,
              bottom: -110,
              child: _Glow(size: 210, color: _amber.withValues(alpha: 0.13)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontal = constraints.maxWidth >= 540;
                  final profileDetails = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: const Text(
                          'GUEST MODE',
                          style: TextStyle(
                            color: Color(0xFF9FE8DE),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 11),
                      Text(
                        'Guest profile',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Sign in to prepare your account. Booking and profile sync will be connected with Firebase in a later update.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.74),
                          height: 1.45,
                        ),
                      ),
                    ],
                  );
                  final signInButton = FilledButton.icon(
                    onPressed: onSignIn,
                    style: FilledButton.styleFrom(
                      foregroundColor: _navy,
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.login_rounded, size: 19),
                    label: const Text(
                      'Open sign in',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  );

                  if (!horizontal) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _GuestAvatar(),
                        const SizedBox(height: 18),
                        profileDetails,
                        const SizedBox(height: 20),
                        signInButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      const _GuestAvatar(),
                      const SizedBox(width: 20),
                      Expanded(child: profileDetails),
                      const SizedBox(width: 22),
                      signInButton,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestAvatar extends StatelessWidget {
  const _GuestAvatar();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.72),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(AppAssets.logo, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          right: -5,
          bottom: -5,
          child: Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: GuestProfileHero._teal,
              shape: BoxShape.circle,
              border: Border.all(color: GuestProfileHero._navy, width: 3),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
