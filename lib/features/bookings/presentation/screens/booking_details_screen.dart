import 'package:flutter/material.dart';

import '../widgets/bookings_placeholder_page.dart';

class BookingDetailsScreen extends StatelessWidget {
  const BookingDetailsScreen({this.bookingId, super.key});

  final String? bookingId;

  @override
  Widget build(BuildContext context) {
    return const BookingsPlaceholderPage(
      title: 'Booking details',
      description:
          'The selected booking timeline and service details will appear here.',
    );
  }
}
