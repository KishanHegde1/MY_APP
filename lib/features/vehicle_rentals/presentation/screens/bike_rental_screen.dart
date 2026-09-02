import 'package:flutter/material.dart';

class BikeRentalScreen extends StatelessWidget {
  const BikeRentalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bike rentals')),
      body: const Center(
        child: Text('Available rental bikes will appear here.'),
      ),
    );
  }
}
