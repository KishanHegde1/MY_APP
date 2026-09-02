import 'package:flutter/material.dart';

import '../widgets/notifications_placeholder_page.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotificationsPlaceholderPage(
      title: 'Notification preferences',
      description:
          'Push, email, and service notification choices will be configured here.',
    );
  }
}
