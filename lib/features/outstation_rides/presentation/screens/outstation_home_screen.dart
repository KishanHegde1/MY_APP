import 'package:flutter/material.dart';

class OutstationHomeScreen extends StatelessWidget {
  const OutstationHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outstation rides')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.route_outlined, size: 72),
          const SizedBox(height: 16),
          Text(
            'Plan an intercity trip',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // TODO: Navigate to trip details through the app router.
            },
            child: const Text('Plan trip'),
          ),
        ],
      ),
    );
  }
}
