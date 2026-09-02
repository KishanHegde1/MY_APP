import 'package:flutter/material.dart';

import '../widgets/bookings_placeholder_page.dart';

class ActiveBookingsScreen extends StatelessWidget {
  const ActiveBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookingsPlaceholderPage(
      title: 'Active bookings',
      description: 'Confirmed and in-progress bookings will appear here.',
    );
  }
}
