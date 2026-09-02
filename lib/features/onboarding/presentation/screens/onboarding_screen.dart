import 'package:flutter/material.dart';

import '../widgets/onboarding_page.dart';

/// Introduces the main groups of services available in the app.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome')),
      body: const OnboardingPage(
        icon: Icons.explore_outlined,
        title: 'Services in one place',
        description: 'Discover rides, vehicle rentals, rooms, and properties.',
      ),
    );
  }
}
