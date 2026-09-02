import 'package:flutter/material.dart';

const authNavy = Color(0xFF132238);
const authBlue = Color(0xFF2563EB);
const authTeal = Color(0xFF14B8A6);
const authAmber = Color(0xFFF59E0B);

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
    this.showBackButton = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF132238) : Colors.white;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0B1320)
          : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF0B1320), Color(0xFF101D2E)]
                      : const [
                          Color(0xFFF8FAFC),
                          Color(0xFFEFF6FF),
                          Color(0xFFF0FDFA),
                        ],
                ),
              ),
            ),
          ),
          const Positioned(
            right: -95,
            top: -120,
            child: _Glow(color: authBlue, size: 310),
          ),
          const Positioned(
            left: -120,
            bottom: -150,
            child: _Glow(color: authTeal, size: 360),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth >= 700
                    ? 32.0
                    : 18.0;

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    32 + MediaQuery.viewInsetsOf(context).bottom,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              if (showBackButton)
                                IconButton.filledTonal(
                                  onPressed: () {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                  tooltip: 'Back',
                                  icon: const Icon(Icons.arrow_back_rounded),
                                ),
                              const Spacer(),
                              const AuthLogo(compact: true),
                            ],
                          ),
                          const SizedBox(height: 26),
                          Container(
                            padding: EdgeInsets.all(
                              constraints.maxWidth >= 520 ? 34 : 24,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: authNavy.withValues(
                                    alpha: isDark ? 0.3 : 0.09,
                                  ),
                                  blurRadius: 34,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: AutofillGroup(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [authBlue, authTeal],
                                      ),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    title,
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          height: 1.15,
                                          letterSpacing: -0.7,
                                        ),
                                  ),
                                  const SizedBox(height: 9),
                                  Text(
                                    subtitle,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      color: isDark
                                          ? const Color(0xFFB6C4D6)
                                          : const Color(0xFF64748B),
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  child,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = compact ? 42.0 : 66.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(compact ? 13 : 20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 10 : 17),
            child: Image.asset(
              'assets/images/multi_service_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const ColoredBox(
                color: Color(0xFFF8FAFC),
                child: Icon(Icons.route_rounded, color: authBlue),
              ),
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Multi Service',
                style: TextStyle(
                  color: isDark ? Colors.white : authNavy,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const Text(
                'Move. Rent. Live.',
                style: TextStyle(
                  color: authTeal,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({required this.text, super.key, this.optional = false});

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text(
            'Optional',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class AuthNotice extends StatelessWidget {
  const AuthNotice({
    required this.text,
    super.key,
    this.icon = Icons.info_outline,
  });

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? authBlue.withValues(alpha: 0.13)
            : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: authBlue.withValues(alpha: isDark ? 0.28 : 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? const Color(0xFF93C5FD) : authBlue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFF475569),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthErrorNotice extends StatelessWidget {
  const AuthErrorNotice({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF7F1D1D).withValues(alpha: 0.24)
            : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? const Color(0xFFFECACA)
                    : const Color(0xFF991B1B),
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration authFieldDecoration(
  BuildContext context, {
  required String hintText,
  required IconData icon,
  Widget? suffixIcon,
  String? prefixText,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final borderColor = isDark
      ? Colors.white.withValues(alpha: 0.12)
      : const Color(0xFFD7E0EA);

  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(
      color: isDark ? const Color(0xFF7C8CA2) : const Color(0xFF94A3B8),
      fontSize: 14,
    ),
    prefixIcon: Icon(icon, color: isDark ? const Color(0xFF7DD3FC) : authBlue),
    prefixText: prefixText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: isDark ? const Color(0xFF0F1B2B) : const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    enabledBorder: border(borderColor),
    focusedBorder: border(authBlue, 1.6),
    errorBorder: border(const Color(0xFFDC2626)),
    focusedErrorBorder: border(const Color(0xFFDC2626), 1.6),
  );
}

void showAuthPendingMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.07),
        ),
      ),
    );
  }
}
