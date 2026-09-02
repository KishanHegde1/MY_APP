import 'package:flutter/material.dart';

import '../widgets/outstation_trip_summary.dart';

class OutstationCheckoutScreen extends StatelessWidget {
  const OutstationCheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review outstation trip')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const OutstationTripSummary(),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // TODO: Connect booking creation and payment selection.
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
