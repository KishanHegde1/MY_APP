import 'package:flutter/material.dart';

import '../widgets/driver_placeholder_page.dart';

class ActiveRideScreen extends StatelessWidget {
  const ActiveRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DriverPlaceholderPage(
      title: 'Active ride',
      description:
          'Live trip controls and navigation will be added with map integration.',
    );
  }
}
