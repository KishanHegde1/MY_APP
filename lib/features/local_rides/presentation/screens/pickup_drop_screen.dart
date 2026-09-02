import 'package:flutter/material.dart';

class PickupDropScreen extends StatelessWidget {
  const PickupDropScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup and destination')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const TextField(
            decoration: InputDecoration(
              labelText: 'Pickup location',
              prefixIcon: Icon(Icons.my_location_outlined),
            ),
          ),
          const SizedBox(height: 16),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Destination',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // TODO: Validate locations and request fare options.
            },
            child: const Text('Find rides'),
          ),
        ],
      ),
    );
  }
}
