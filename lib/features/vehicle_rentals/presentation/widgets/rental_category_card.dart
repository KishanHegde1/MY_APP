import 'package:flutter/material.dart';

class RentalCategoryCard extends StatelessWidget {
  const RentalCategoryCard({
    required this.title,
    required this.icon,
    this.onTap,
    super.key,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(leading: Icon(icon), title: Text(title), onTap: onTap),
    );
  }
}
