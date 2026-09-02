import 'package:flutter/material.dart';

class RideCompletedScreen extends StatelessWidget {
  const RideCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride complete')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 72),
            SizedBox(height: 16),
            Text('The completed ride summary will appear here.'),
          ],
        ),
      ),
    );
  }
}
