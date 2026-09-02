import 'package:firebase_auth/firebase_auth.dart';

String firebaseAuthMessage(Object error) {
  if (error is! FirebaseAuthException) {
    return 'Something went wrong. Please try again.';
  }

  return switch (error.code) {
    'invalid-email' => 'Enter a valid email address.',
    'user-disabled' =>
      'This account has been disabled. Contact support for help.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'The email or password is incorrect.',
    'email-already-in-use' =>
      'An account already exists for this email. Try signing in instead.',
    'weak-password' => 'Choose a stronger password with at least 8 characters.',
    'operation-not-allowed' =>
      'This sign-in method is not enabled in Firebase Console yet.',
    'too-many-requests' =>
      'Too many attempts were made. Please wait and try again.',
    'network-request-failed' => 'Check your internet connection and try again.',
    'invalid-phone-number' || 'missing-phone-number' =>
      'Enter a valid mobile number including the country code.',
    'quota-exceeded' =>
      'The SMS limit has been reached. Please try again later.',
    'app-not-authorized' =>
      'This app is not authorized for Firebase phone sign-in.',
    'captcha-check-failed' =>
      'Phone verification could not confirm this device. Please try again.',
    'invalid-verification-code' =>
      'That verification code is incorrect. Check it and try again.',
    'invalid-verification-id' || 'session-expired' =>
      'This verification session expired. Request a new code.',
    'credential-already-in-use' =>
      'This phone number is already connected to another account.',
    'requires-recent-login' =>
      'For security, sign in again before changing your account details.',
    _ => error.message ?? 'Authentication failed. Please try again.',
  };
}
