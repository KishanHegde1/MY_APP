import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app_flutter/app.dart';

void main() {
  testWidgets('startup, guest home, profile, and theme flow work', (
    tester,
  ) async {
    await tester.pumpWidget(const MultiServiceApp());

    expect(find.text('Multi Service'), findsOneWidget);
    expect(find.text('Getting everything ready'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1900));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Continue with phone OTP'), findsOneWidget);
    expect(find.text('Explore services as a guest'), findsOneWidget);

    await tester.ensureVisible(find.text('Continue with phone OTP'));
    await tester.tap(find.text('Continue with phone OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Continue with phone'), findsOneWidget);
    expect(
      find.textContaining('Firebase Console test numbers'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Use email and password instead'));
    await tester.tap(find.text('Use email and password instead'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Explore services as a guest'));
    await tester.tap(find.text('Explore services as a guest'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a service'), findsOneWidget);
    expect(find.text('Local rides'), findsOneWidget);
    expect(find.text('Bookings'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Guest profile'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);

    await tester.ensureVisible(find.text('Dark'));
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
  });
}
