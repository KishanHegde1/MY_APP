import 'package:flutter/material.dart';

import '../widgets/bookings_placeholder_page.dart';

class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BookingsPlaceholderPage(
      title: 'My bookings',
      description: 'Your bookings will appear here once the API is connected.',
    );
  }
}
