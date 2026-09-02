import 'package:flutter/material.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    required this.title,
    this.subtitle,
    this.onTap,
    super.key,
  });
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: const Icon(Icons.directions_car_outlined),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
    ),
  );
}
