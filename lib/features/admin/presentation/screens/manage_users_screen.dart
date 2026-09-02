import 'package:flutter/material.dart';

import '../widgets/admin_placeholder_page.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminPlaceholderPage(
      title: 'Manage users',
      description:
          'Authorized user and role administration tools will appear here.',
    );
  }
}
