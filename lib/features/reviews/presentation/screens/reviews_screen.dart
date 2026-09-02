import 'package:flutter/material.dart';

import '../widgets/reviews_placeholder_page.dart';

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ReviewsPlaceholderPage(
      title: 'Reviews',
      description: 'Verified reviews for completed services will appear here.',
    );
  }
}
