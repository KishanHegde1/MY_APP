import 'package:flutter/material.dart';

class RentalVehicleDetailsScreen extends StatelessWidget {
  const RentalVehicleDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rental vehicle details')),
      body: const Center(
        child: Text('Vehicle details and availability will appear here.'),
      ),
    );
  }
}
