import 'package:flutter/material.dart';

import '../widgets/admin_placeholder_page.dart';

class ManageBookingsScreen extends StatelessWidget {
  const ManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminPlaceholderPage(
      title: 'Manage bookings',
      description:
          'Authorized booking oversight and dispute tools will appear here.',
    );
  }
}
