import 'package:flutter/material.dart';

import '../widgets/bookings_placeholder_page.dart';

class CancelledBookingsScreen extends StatelessWidget {
  const CancelledBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookingsPlaceholderPage(
      title: 'Cancelled bookings',
      description: 'Cancelled and expired bookings will appear here.',
    );
  }
}
