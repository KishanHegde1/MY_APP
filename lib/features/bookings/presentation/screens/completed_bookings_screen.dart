import 'package:flutter/material.dart';

import '../widgets/bookings_placeholder_page.dart';

class CompletedBookingsScreen extends StatelessWidget {
  const CompletedBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookingsPlaceholderPage(
      title: 'Completed bookings',
      description: 'Completed service bookings will appear here.',
    );
  }
}
