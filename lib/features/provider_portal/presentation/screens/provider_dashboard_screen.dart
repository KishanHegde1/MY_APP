import 'package:flutter/material.dart';

import '../widgets/provider_placeholder_page.dart';

class ProviderDashboardScreen extends StatelessWidget {
  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderPlaceholderPage(
      title: 'Provider dashboard',
      description:
          'Provider activity, listings, bookings, and earnings will appear here.',
    );
  }
}
