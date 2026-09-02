import 'package:flutter/material.dart';

import '../widgets/driver_placeholder_page.dart';

class DriverDocumentsScreen extends StatelessWidget {
  const DriverDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DriverPlaceholderPage(
      title: 'Driver documents',
      description:
          'Driver identity and vehicle document verification will be added here.',
    );
  }
}
