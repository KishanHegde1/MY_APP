import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import 'auth_screen_shell.dart';
import 'firebase_auth_messages.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isSubmitting = false;
  bool _requestSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      TextInput.finishAutofillContext(shouldSave: false);
      if (!mounted) return;
      setState(() => _requestSent = true);
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      // Avoid revealing whether a particular email has an account.
      if (error.code == 'user-not-found') {
        setState(() => _requestSent = true);
      } else {
        setState(() => _errorMessage = firebaseAuthMessage(error));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = firebaseAuthMessage(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      title: 'Reset your password',
      subtitle:
          'Enter the email linked to your account and Firebase will send you a secure reset link.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthNotice(
              text: _requestSent
                  ? 'If an account exists for ${_emailController.text.trim()}, a password-reset link has been sent. Check your inbox and spam folder.'
                  : 'For your security, the reset link expires and can only be used once.',
              icon: _requestSent
                  ? Icons.mark_email_read_outlined
                  : Icons.lock_reset_rounded,
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              AuthErrorNotice(text: _errorMessage!),
            ],
            if (!_requestSent) ...[
              const SizedBox(height: 24),
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
                validator: (rawValue) {
                  final value = rawValue?.trim() ?? '';
                  if (value.isEmpty) return 'Enter your email address';
                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
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
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    _isSubmitting ? 'Sending link...' : 'Send reset link',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => context.go(AppRoutes.login),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
