import 'package:flutter/material.dart';

class OutstationTripSummary extends StatelessWidget {
  const OutstationTripSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Trip dates, route, and fare will appear here.'),
      ),
    );
  }
}
