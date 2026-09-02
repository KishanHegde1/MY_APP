import 'package:flutter/material.dart';

import '../widgets/admin_placeholder_page.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminPlaceholderPage(
      title: 'Admin dashboard',
      description:
          'Role-protected operational summaries and moderation tools will appear here.',
    );
  }
}
