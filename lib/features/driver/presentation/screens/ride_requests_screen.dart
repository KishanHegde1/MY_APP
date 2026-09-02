import 'package:flutter/material.dart';

import '../widgets/driver_placeholder_page.dart';

class RideRequestsScreen extends StatelessWidget {
  const RideRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DriverPlaceholderPage(
      title: 'Ride requests',
      description:
          'Eligible ride requests will appear after driver matching is added.',
    );
  }
}
