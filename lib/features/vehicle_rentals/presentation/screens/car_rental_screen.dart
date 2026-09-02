import 'package:flutter/material.dart';

class CarRentalScreen extends StatelessWidget {
  const CarRentalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Car rentals')),
      body: const Center(
        child: Text('Available rental cars will appear here.'),
      ),
    );
  }
}
