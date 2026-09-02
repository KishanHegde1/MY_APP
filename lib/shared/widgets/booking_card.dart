import 'package:flutter/material.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    required this.title,
    required this.status,
    this.onTap,
    super.key,
  });
  final String title;
  final String status;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(onTap: onTap, title: Text(title), subtitle: Text(status)),
  );
}
