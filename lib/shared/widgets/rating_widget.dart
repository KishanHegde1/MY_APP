import 'package:flutter/material.dart';

class RatingWidget extends StatelessWidget {
  const RatingWidget({required this.rating, super.key});
  final double rating;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.star, color: Colors.amber, size: 18),
      const SizedBox(width: 4),
      Text(rating.toStringAsFixed(1)),
    ],
  );
}
