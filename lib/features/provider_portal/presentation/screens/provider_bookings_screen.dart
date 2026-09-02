import 'package:flutter/material.dart';

import '../widgets/provider_placeholder_page.dart';

class ProviderBookingsScreen extends StatelessWidget {
  const ProviderBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderPlaceholderPage(
      title: 'Provider bookings',
      description:
          'Incoming and historical provider bookings will appear here.',
    );
  }
}
