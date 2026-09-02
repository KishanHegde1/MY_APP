import 'package:flutter/material.dart';

class RideTrackingScreen extends StatelessWidget {
  const RideTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track ride')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 72),
            SizedBox(height: 16),
            Text('Live map tracking will be added here.'),
          ],
        ),
      ),
    );
  }
}
