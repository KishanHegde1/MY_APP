import 'package:flutter/material.dart';

class OutstationCarDetailsScreen extends StatelessWidget {
  const OutstationCarDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Car details')),
      body: const Center(
        child: Text('Vehicle, driver, and fare details will appear here.'),
      ),
    );
  }
}
