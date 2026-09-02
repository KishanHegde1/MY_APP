import 'package:flutter/material.dart';

class PropertyDetailsScreen extends StatelessWidget {
  const PropertyDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Property details')),
      body: const Center(
        child: Text('Property photos, amenities, and rent will appear here.'),
      ),
    );
  }
}
