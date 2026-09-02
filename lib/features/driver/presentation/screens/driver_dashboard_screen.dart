import 'package:flutter/material.dart';

import '../widgets/driver_placeholder_page.dart';

class DriverDashboardScreen extends StatelessWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DriverPlaceholderPage(
      title: 'Driver dashboard',
      description:
          'Availability, ride activity, and driver status will appear here.',
    );
  }
}
