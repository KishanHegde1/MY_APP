import 'package:flutter/material.dart';

class RentalCheckoutScreen extends StatelessWidget {
  const RentalCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review vehicle rental')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Rental dates, vehicle, and price will appear here.'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // TODO: Create the rental booking after backend integration.
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
