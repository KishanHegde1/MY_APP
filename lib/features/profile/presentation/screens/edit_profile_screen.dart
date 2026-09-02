import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  bool _isSaving = false;
  bool _isSendingVerification = false;
  String? _errorMessage;
  String? _successMessage;
  String? _pendingEmail;

  @override
  void initState() {
    super.initState();
    final user = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _nameController.addListener(_clearFeedbackAfterEdit);
    _emailController.addListener(_clearFeedbackAfterEdit);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_clearFeedbackAfterEdit)
      ..dispose();
    _emailController
      ..removeListener(_clearFeedbackAfterEdit)
      ..dispose();
    super.dispose();
  }

  void _clearFeedbackAfterEdit() {
    if (_errorMessage == null && _successMessage == null) return;
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });
  }

  Future<void> _saveProfile() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Your session ended. Please sign in again.';
        _successMessage = null;
      });
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final currentEmail = _clean(user.email);
    final nameChanged = _clean(user.displayName) != name;
    final emailChanged =
        email.isNotEmpty && currentEmail?.toLowerCase() != email.toLowerCase();

    if (!nameChanged && !emailChanged) {
      setState(() {
        _errorMessage = null;
        _successMessage = 'Your profile is already up to date.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    var nameSaved = false;
    try {
      if (nameChanged) {
        await user.updateDisplayName(name);
        nameSaved = true;
      }
      if (emailChanged) {
        await user.verifyBeforeUpdateEmail(email);
      }
      await user.reload();

      TextInput.finishAutofillContext();
      if (!mounted) return;
      setState(() {
        _pendingEmail = emailChanged ? email : _pendingEmail;
        _successMessage = emailChanged
            ? 'Your name is saved. We sent a verification link to $email. '
                  'Your email changes after you verify it.'
            : 'Your profile has been updated.';
      });
    } catch (error) {
      try {
        await FirebaseAuth.instance.currentUser?.reload();
      } catch (_) {
        // Preserve the useful profile-update error below.
      }
      if (!mounted) return;
      final reason = _profileErrorMessage(error);
      setState(() {
        _successMessage = null;
        _errorMessage = nameSaved && emailChanged
            ? 'Your name was saved, but the email change could not start. '
                  '$reason'
            : reason;
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _sendCurrentEmailVerification() async {
    final user = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser;
    final email = _clean(user?.email);
    if (user == null || email == null) {
      setState(() {
        _errorMessage = 'Add an email address before requesting verification.';
        _successMessage = null;
      });
      return;
    }
    if (user.emailVerified) {
      setState(() {
        _errorMessage = null;
        _successMessage = 'Your current email is already verified.';
      });
      return;
    }

    setState(() {
      _isSendingVerification = true;
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await user.sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _successMessage = 'Verification link sent to $email.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = _profileErrorMessage(error));
    } finally {
      if (mounted) setState(() => _isSendingVerification = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Firebase.apps.isEmpty
        ? null
        : FirebaseAuth.instance.currentUser;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back to profile',
          onPressed: _leaveScreen,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Update profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: user == null
            ? _ProfileAccessState(
                firebaseAvailable: Firebase.apps.isNotEmpty,
                onSignIn: () => context.push(AppRoutes.login),
                onBack: _leaveScreen,
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 600
                      ? 18.0
                      : 32.0;
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      12,
                      horizontalPadding,
                      36,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _EditProfileHeader(user: user),
                            const SizedBox(height: 20),
                            _buildForm(context, user),
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

  Widget _buildForm(BuildContext context, User user) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentEmail = _clean(user.email);
    final phone = _clean(user.phoneNumber);
    final busy = _isSaving || _isSendingVerification;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: theme.brightness == Brightness.light
            ? [
                BoxShadow(
                  color: const Color(0xFF172554).withValues(alpha: 0.06),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ]
            : null,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Personal details',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Keep the details people use to recognise you current.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 18),
              _ProfileStatusNotice.error(text: _errorMessage!),
            ],
            if (_successMessage != null) ...[
              const SizedBox(height: 18),
              _ProfileStatusNotice.success(text: _successMessage!),
            ],
            const SizedBox(height: 24),
            const _FieldLabel(
              label: 'Full name',
              helper: 'Shown across your Multi Service account',
            ),
            const SizedBox(height: 9),
            TextFormField(
              controller: _nameController,
              enabled: !busy,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              decoration: _profileFieldDecoration(
                context,
                hintText: 'Your full name',
                icon: Icons.person_outline_rounded,
              ),
              validator: _validateName,
            ),
            const SizedBox(height: 20),
            _FieldLabel(
              label: currentEmail == null
                  ? 'Email address (optional)'
                  : 'Email address',
              helper: 'A new address is added only after you verify it',
            ),
            const SizedBox(height: 9),
            TextFormField(
              controller: _emailController,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              inputFormatters: [LengthLimitingTextInputFormatter(254)],
              onFieldSubmitted: (_) {
                if (!busy) _saveProfile();
              },
              decoration: _profileFieldDecoration(
                context,
                hintText: 'you@example.com',
                icon: Icons.alternate_email_rounded,
                suffixIcon: currentEmail != null && user.emailVerified
                    ? const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF0F9D7A),
                      )
                    : null,
              ),
              validator: (value) =>
                  _validateEmail(value, hasCurrentEmail: currentEmail != null),
            ),
            const SizedBox(height: 10),
            _EmailVerificationStatus(
              currentEmail: currentEmail,
              isVerified: user.emailVerified,
              pendingEmail: _pendingEmail,
              isSending: _isSendingVerification,
              onSendVerification: _sendCurrentEmailVerification,
            ),
            if (phone != null) ...[
              const SizedBox(height: 20),
              const _FieldLabel(
                label: 'Verified mobile number',
                helper: 'Phone changes require a fresh OTP check',
              ),
              const SizedBox(height: 9),
              TextFormField(
                initialValue: phone,
                readOnly: true,
                enableInteractiveSelection: true,
                decoration: _profileFieldDecoration(
                  context,
                  hintText: 'Verified mobile number',
                  icon: Icons.phone_iphone_rounded,
                  suffixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                ),
              ),
            ],
            const SizedBox(height: 26),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: busy ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFF2563EB,
                  ).withValues(alpha: 0.48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(
                  _isSaving ? 'Saving changes...' : 'Save changes',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: busy ? null : _leaveScreen,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  void _leaveScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.profile);
    }
  }

  static String? _validateName(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return 'Enter your full name';
    if (value.length < 2) return 'Name must contain at least 2 characters';
    return null;
  }

  static String? _validateEmail(
    String? rawValue, {
    required bool hasCurrentEmail,
  }) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) {
      return hasCurrentEmail
          ? 'Your current email cannot be removed from this screen'
          : null;
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  static String _profileErrorMessage(Object error) {
    if (error is! FirebaseAuthException) {
      return 'We could not update your profile. Please try again.';
    }

    return switch (error.code) {
      'invalid-email' => 'Enter a valid email address.',
      'email-already-in-use' =>
        'That email is already connected to another account.',
      'requires-recent-login' =>
        'For your security, sign out and sign in again before changing this detail.',
      'too-many-requests' =>
        'Too many requests were made. Please wait a moment and try again.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      'user-disabled' =>
        'This account is disabled. Contact support for assistance.',
      'user-token-expired' ||
      'invalid-user-token' => 'Your session expired. Please sign in again.',
      'operation-not-allowed' =>
        'Email changes are not available for this account right now.',
      _ => error.message ?? 'We could not update your profile. Try again.',
    };
  }
}

class _EditProfileHeader extends StatelessWidget {
  const _EditProfileHeader({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final name = _clean(user.displayName) ?? 'Multi Service member';
    final photoUrl = _clean(user.photoURL);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF132238), Color(0xFF1D3F67), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4ED8).withValues(alpha: 0.2),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        children: [
          _AccountAvatar(label: name, photoUrl: photoUrl),
          const SizedBox(width: 17),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  photoUrl == null
                      ? 'Your initials are used for your account photo.'
                      : 'Photo synced from your sign-in provider.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFF9FE8DE),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.label, required this.photoUrl});

  final String label;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final fallback = ColoredBox(
      color: const Color(0xFFEFF6FF),
      child: Center(
        child: Text(
          _initials(label),
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: photoUrl == null
            ? fallback
            : Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }

  static String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'MS';
    if (words.length == 1) {
      return words.first
          .substring(0, words.first.length.clamp(1, 2))
          .toUpperCase();
    }
    return '${words.first[0]}${words.last[0]}'.toUpperCase();
  }
}

class _EmailVerificationStatus extends StatelessWidget {
  const _EmailVerificationStatus({
    required this.currentEmail,
    required this.isVerified,
    required this.pendingEmail,
    required this.isSending,
    required this.onSendVerification,
  });

  final String? currentEmail;
  final bool isVerified;
  final String? pendingEmail;
  final bool isSending;
  final VoidCallback onSendVerification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (pendingEmail != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.mark_email_unread_outlined,
              color: Color(0xFF2563EB),
              size: 17,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Verification pending for $pendingEmail',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    }

    if (currentEmail == null) {
      return Text(
        'We will email a secure link before adding a new address.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Row(
      children: [
        Icon(
          isVerified ? Icons.verified_rounded : Icons.info_outline_rounded,
          size: 17,
          color: isVerified ? const Color(0xFF0F9D7A) : const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            isVerified
                ? 'Current email verified'
                : 'Current email not verified',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (!isVerified)
          TextButton(
            onPressed: isSending ? null : onSendVerification,
            child: isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Send link'),
          ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.helper});

  final String label;
  final String helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          helper,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ProfileStatusNotice extends StatelessWidget {
  const _ProfileStatusNotice._({
    required this.text,
    required this.icon,
    required this.color,
  });

  const _ProfileStatusNotice.error({required String text})
    : this._(
        text: text,
        icon: Icons.error_outline_rounded,
        color: const Color(0xFFDC2626),
      );

  const _ProfileStatusNotice.success({required String text})
    : this._(
        text: text,
        icon: Icons.check_circle_outline_rounded,
        color: const Color(0xFF0F9D7A),
      );

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAccessState extends StatelessWidget {
  const _ProfileAccessState({
    required this.firebaseAvailable,
    required this.onSignIn,
    required this.onBack,
  });

  final bool firebaseAvailable;
  final VoidCallback onSignIn;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Icon(
                      firebaseAvailable
                          ? Icons.person_outline_rounded
                          : Icons.cloud_off_outlined,
                      color: colorScheme.onPrimaryContainer,
                      size: 29,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  firebaseAvailable
                      ? 'Sign in to update your profile'
                      : 'Profile editing is unavailable',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  firebaseAvailable
                      ? 'Your profile stays private until you sign in to your account.'
                      : 'Firebase is not available on this device right now. You can still return to your profile.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                if (firebaseAvailable)
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: onSignIn,
                      icon: const Icon(Icons.login_rounded),
                      label: const Text(
                        'Sign in',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onBack,
                  child: const Text('Back to profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _profileFieldDecoration(
  BuildContext context, {
  required String hintText,
  required IconData icon,
  Widget? suffixIcon,
}) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(16),
    borderSide: BorderSide(color: colorScheme.outlineVariant),
  );

  return InputDecoration(
    hintText: hintText,
    prefixIcon: Icon(icon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: theme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.34)
        : const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    enabledBorder: border,
    disabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.7),
    ),
    errorBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFFDC2626)),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.7),
    ),
  );
}
