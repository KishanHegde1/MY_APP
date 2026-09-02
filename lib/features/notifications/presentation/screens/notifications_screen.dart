import 'package:flutter/material.dart';

import '../widgets/notifications_placeholder_page.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotificationsPlaceholderPage(
      title: 'Notifications',
      description:
          'Booking, ride, payment, and account notifications will appear here.',
    );
  }
}
