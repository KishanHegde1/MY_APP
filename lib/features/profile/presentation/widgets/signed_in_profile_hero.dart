import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignedInProfileHero extends StatelessWidget {
  const SignedInProfileHero({
    required this.user,
    required this.onUpdateProfile,
    required this.onSignOut,
    super.key,
  });

  final User user;
  final VoidCallback onUpdateProfile;
  final VoidCallback onSignOut;

  static const _navy = Color(0xFF132238);
  static const _blue = Color(0xFF2563EB);
  static const _teal = Color(0xFF14B8A6);
  static const _amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    final displayName = _clean(user.displayName);
    final email = _clean(user.email);
    final phone = _clean(user.phoneNumber);
    final photoUrl = _clean(user.photoURL);
    final title = displayName ?? 'Multi Service member';

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
                  final details = _AccountDetails(
                    title: title,
                    email: email,
                    phone: phone,
                    emailVerified: user.emailVerified,
                  );
                  final updateButton = FilledButton.icon(
                    onPressed: onUpdateProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: _navy,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text(
                      'Update profile',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  );
                  final signOutButton = OutlinedButton.icon(
                    onPressed: onSignOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 15,
                      ),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.36),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 19),
                    label: const Text(
                      'Sign out',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  );
                  final actions = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      updateButton,
                      const SizedBox(height: 9),
                      signOutButton,
                    ],
                  );

                  if (!horizontal) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SignedInAvatar(label: title, photoUrl: photoUrl),
                        const SizedBox(height: 18),
                        details,
                        const SizedBox(height: 20),
                        SizedBox(width: double.infinity, child: actions),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      _SignedInAvatar(label: title, photoUrl: photoUrl),
                      const SizedBox(width: 20),
                      Expanded(child: details),
                      const SizedBox(width: 22),
                      SizedBox(width: 172, child: actions),
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

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}

class _AccountDetails extends StatelessWidget {
  const _AccountDetails({
    required this.title,
    required this.email,
    required this.phone,
    required this.emailVerified,
  });

  final String title;
  final String? email;
  final String? phone;
  final bool emailVerified;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 13,
                color: Color(0xFF9FE8DE),
              ),
              SizedBox(width: 5),
              Text(
                'SIGNED IN',
                style: TextStyle(
                  color: Color(0xFF9FE8DE),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 11),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 8),
        if (email != null)
          _IdentityLine(
            icon: Icons.alternate_email_rounded,
            value: email!,
            suffix: emailVerified ? 'Verified' : 'Not verified',
          ),
        if (email != null && phone != null) const SizedBox(height: 6),
        if (phone != null)
          _IdentityLine(
            icon: Icons.phone_iphone_rounded,
            value: phone!,
            suffix: 'Verified',
          ),
        if (email == null && phone == null)
          Text(
            'Your account is connected securely with Firebase.',
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
              height: 1.45,
            ),
          ),
      ],
    );
  }
}

class _IdentityLine extends StatelessWidget {
  const _IdentityLine({
    required this.icon,
    required this.value,
    required this.suffix,
  });

  final IconData icon;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.white.withValues(alpha: 0.74)),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          suffix,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.58),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SignedInAvatar extends StatelessWidget {
  const _SignedInAvatar({required this.label, required this.photoUrl});

  final String label;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = _AvatarFallback(initials: _initials(label));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(4),
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
            child: photoUrl == null
                ? fallback
                : Image.network(
                    photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => fallback,
                  ),
          ),
        ),
        Positioned(
          right: -5,
          bottom: -5,
          child: Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: SignedInProfileHero._teal,
              shape: BoxShape.circle,
              border: Border.all(color: SignedInProfileHero._navy, width: 3),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 15,
            ),
          ),
        ),
      ],
    );
  }

  static String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'MS';
    if (parts.length == 1) {
      final word = parts.first;
      return word.substring(0, word.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEFF6FF),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: SignedInProfileHero._blue,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
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
