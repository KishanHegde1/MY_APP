import 'package:flutter/material.dart';

import '../widgets/rental_category_card.dart';

class VehicleRentalHomeScreen extends StatelessWidget {
  const VehicleRentalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle rentals')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RentalCategoryCard(
            title: 'Bike rentals',
            icon: Icons.two_wheeler_outlined,
          ),
          RentalCategoryCard(
            title: 'Self-drive cars',
            icon: Icons.key_outlined,
          ),
          RentalCategoryCard(
            title: 'Cars with drivers',
            icon: Icons.person_pin_circle_outlined,
          ),
        ],
      ),
    );
  }
}
