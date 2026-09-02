import 'package:flutter/material.dart';

import '../widgets/reviews_placeholder_page.dart';

class WriteReviewScreen extends StatelessWidget {
  const WriteReviewScreen({this.bookingId, super.key});

  final String? bookingId;

  @override
  Widget build(BuildContext context) {
    return const ReviewsPlaceholderPage(
      title: 'Write a review',
      description:
          'Rating and review input will be enabled for completed bookings.',
    );
  }
}
