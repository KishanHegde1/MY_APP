import 'package:flutter/material.dart';

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip details')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const TextField(decoration: InputDecoration(labelText: 'From')),
          const SizedBox(height: 16),
          const TextField(decoration: InputDecoration(labelText: 'To')),
          const SizedBox(height: 16),
          const TextField(
            readOnly: true,
            decoration: InputDecoration(labelText: 'Travel date'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // TODO: Validate trip details and request available cars.
            },
            child: const Text('Find cars'),
          ),
        ],
      ),
    );
  }
}
