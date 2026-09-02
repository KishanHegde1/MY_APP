import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../routes/app_routes.dart';
import 'auth_screen_shell.dart';
import 'firebase_auth_messages.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  String? _verificationId;
  int? _resendToken;
  String? _statusMessage;
  String? _errorMessage;
  bool _codeRequested = false;
  bool _isRequesting = false;
  bool _isVerifying = false;

  bool get _isBusy => _isRequesting || _isVerifying;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestCode({bool resend = false}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_phoneFormKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isRequesting = true;
      _errorMessage = null;
      _statusMessage = resend
          ? 'Requesting a new verification code…'
          : 'Requesting your verification code…';
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _normalizedPhone,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resend ? _resendToken : null,
        verificationCompleted: (credential) async {
          if (!mounted) return;
          setState(() {
            _isRequesting = false;
            _statusMessage = 'Phone number detected. Completing sign-in…';
          });
          await _completeSignIn(credential);
        },
        verificationFailed: (error) {
          if (!mounted) return;
          setState(() {
            _isRequesting = false;
            _errorMessage = firebaseAuthMessage(error);
            _statusMessage = null;
          });
        },
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _codeRequested = true;
            _isRequesting = false;
            _codeController.clear();
            _statusMessage =
                'Firebase accepted the request. Enter the 6-digit code for ${_phoneController.text.trim()}.';
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _isRequesting = false;
            if (_codeRequested) {
              _statusMessage =
                  'Automatic detection timed out. Enter the code from your SMS.';
            }
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isRequesting = false;
        _errorMessage = firebaseAuthMessage(error);
        _statusMessage = null;
      });
    }
  }

  Future<void> _verifyCode() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_codeFormKey.currentState?.validate() ?? false)) return;

    final verificationId = _verificationId;
    if (verificationId == null) {
      setState(() {
        _errorMessage = 'Request a new verification code before continuing.';
      });
      return;
    }

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: _codeController.text.trim(),
    );
    await _completeSignIn(credential);
  }

  Future<void> _completeSignIn(PhoneAuthCredential credential) async {
    if (!mounted) return;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final result = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = result.user;
      final nameMissing = user?.displayName?.trim().isEmpty ?? true;
      final emailMissing = user?.email?.trim().isEmpty ?? true;
      final needsProfile =
          (result.additionalUserInfo?.isNewUser ?? false) ||
          nameMissing ||
          emailMissing;

      TextInput.finishAutofillContext();
      if (!mounted) return;
      context.go(needsProfile ? AppRoutes.completeProfile : AppRoutes.home);
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = firebaseAuthMessage(error));
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  String get _normalizedPhone {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (_phoneController.text.trim().startsWith('+')) return '+$digits';
    return '+91$digits';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthScreenShell(
      title: 'Continue with phone',
      subtitle:
          'Use a verified mobile number for a quick sign-in. New phone users will complete their profile after verification.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthNotice(
            text:
                _statusMessage ??
                'Enter a 10-digit Indian number or include an international +country code. Firebase Console test numbers work here too.',
            icon: _codeRequested
                ? Icons.mark_email_read_outlined
                : Icons.phonelink_lock_outlined,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            AuthErrorNotice(text: _errorMessage!),
          ],
          const SizedBox(height: 24),
          Form(
            key: _phoneFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AuthFieldLabel(text: 'Mobile number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  enabled: !_isBusy,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()-]')),
                    LengthLimitingTextInputFormatter(20),
                  ],
                  onChanged: (_) {
                    if (_codeRequested) {
                      setState(() {
                        _codeRequested = false;
                        _verificationId = null;
                        _statusMessage = null;
                        _codeController.clear();
                      });
                    }
                  },
                  onFieldSubmitted: (_) {
                    if (!_isBusy) _requestCode();
                  },
                  decoration: authFieldDecoration(
                    context,
                    hintText: '+91 98765 43210',
                    icon: Icons.phone_iphone_rounded,
                  ),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _isBusy ? null : _requestCode,
                    style: FilledButton.styleFrom(
                      backgroundColor: authBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isRequesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.sms_outlined, size: 20),
                    label: Text(
                      _isRequesting
                          ? 'Requesting code…'
                          : _codeRequested
                          ? 'Request a new code'
                          : 'Request verification code',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  '6-digit code',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          AnimatedOpacity(
            opacity: _codeRequested ? 1 : 0.48,
            duration: const Duration(milliseconds: 220),
            child: Form(
              key: _codeFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _codeRequested
                        ? 'Enter the SMS code, or the test code configured in Firebase Console.'
                        : 'Request a code above to unlock verification.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _codeController,
                    enabled: _codeRequested && !_isBusy,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white : authNavy,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 12,
                    ),
                    onFieldSubmitted: (_) {
                      if (!_isBusy) _verifyCode();
                    },
                    decoration:
                        authFieldDecoration(
                          context,
                          hintText: '000000',
                          icon: Icons.password_rounded,
                        ).copyWith(
                          counterText: '',
                          hintStyle: TextStyle(
                            color: isDark
                                ? const Color(0xFF64748B)
                                : const Color(0xFF94A3B8),
                            fontSize: 20,
                            letterSpacing: 9,
                          ),
                        ),
                    validator: (value) {
                      if (!_codeRequested) {
                        return 'Request a verification code first';
                      }
                      if (value == null || value.isEmpty) {
                        return 'Enter the verification code';
                      }
                      if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                        return 'Enter all 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton.icon(
                      onPressed: !_codeRequested || _isBusy
                          ? null
                          : _verifyCode,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? const Color(0xFF93C5FD)
                            : authNavy,
                        side: BorderSide(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.16)
                              : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Icon(Icons.verified_user_outlined, size: 20),
                      label: Text(
                        _isVerifying ? 'Verifying…' : 'Verify and continue',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  if (_codeRequested) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isBusy
                          ? null
                          : () => _requestCode(resend: true),
                      child: const Text('Resend code'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _isBusy ? null : () => context.go(AppRoutes.login),
            child: const Text('Use email and password instead'),
          ),
        ],
      ),
    );
  }

  static String? _validatePhone(String? rawValue) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) return 'Enter your mobile number';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (!value.startsWith('+') && digits.length == 10) return null;
    if (!value.startsWith('+')) {
      return 'Enter 10 Indian digits or include a +country code';
    }
    if (digits.length < 8 || digits.length > 15) {
      return 'Enter a valid mobile number with country code';
    }
    return null;
  }
}
