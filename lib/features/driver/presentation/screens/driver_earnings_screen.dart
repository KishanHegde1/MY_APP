import 'package:flutter/material.dart';

import '../widgets/driver_placeholder_page.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DriverPlaceholderPage(
      title: 'Driver earnings',
      description:
          'Completed-trip earnings and payouts will appear after integration.',
    );
  }
}
