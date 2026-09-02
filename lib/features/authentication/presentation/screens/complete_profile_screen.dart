import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import 'auth_screen_shell.dart';
import 'firebase_auth_messages.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({
    super.key,
    this.initialPhone,
    this.initialEmail,
  });

  final String? initialPhone;
  final String? initialEmail;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(
      text: widget.initialEmail ?? user?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialPhone ?? user?.phoneNumber ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'Your sign-in session ended. Please sign in again.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final emailChanged = user.email?.toLowerCase() != email.toLowerCase();

      if (user.displayName != name) {
        await user.updateDisplayName(name);
      }
      if (emailChanged) {
        await user.verifyBeforeUpdateEmail(email);
      }
      await user.reload();

      TextInput.finishAutofillContext();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              emailChanged
                  ? 'Profile name saved. Check your inbox to verify and add your email.'
                  : 'Your Firebase profile was updated.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      context.go(AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = firebaseAuthMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasVerifiedPhone = _phoneController.text.trim().isNotEmpty;

    return AuthScreenShell(
      title: 'Complete your profile',
      subtitle:
          'Add the essential details that will appear on your Firebase account.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthNotice(
              text:
                  'Your name is saved to Firebase Authentication. A verification link will be sent before a new email is added to your account.',
              icon: Icons.manage_accounts_outlined,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              AuthErrorNotice(text: _errorMessage!),
            ],
            const SizedBox(height: 24),
            if (hasVerifiedPhone) ...[
              const AuthFieldLabel(text: 'Verified mobile number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                readOnly: true,
                decoration: authFieldDecoration(
                  context,
                  hintText: 'Verified phone',
                  icon: Icons.verified_rounded,
                ),
              ),
              const SizedBox(height: 19),
            ],
            const AuthFieldLabel(text: 'Full name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: authFieldDecoration(
                context,
                hintText: 'Your first and last name',
                icon: Icons.person_outline_rounded,
              ),
              validator: _validateName,
            ),
            const SizedBox(height: 19),
            const AuthFieldLabel(text: 'Email address'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              enabled: !_isSubmitting,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              onFieldSubmitted: (_) {
                if (!_isSubmitting) _submit();
              },
              decoration: authFieldDecoration(
                context,
                hintText: 'you@example.com',
                icon: Icons.alternate_email_rounded,
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: authBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: Text(
                  _isSubmitting ? 'Saving profile…' : 'Save and continue',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String? _validateName(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return 'Enter your full name';
    if (value.length < 2 || RegExp(r'\d').hasMatch(value)) {
      return 'Enter a valid name';
    }
    return null;
  }

  static String? _validateEmail(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return 'Enter your email address';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }
}
