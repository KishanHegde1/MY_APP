import 'package:flutter/material.dart';

class AvailableCarsScreen extends StatelessWidget {
  const AvailableCarsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available cars')),
      body: const Center(
        child: Text('Available outstation cars will appear here.'),
      ),
    );
  }
}
