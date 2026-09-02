import 'package:flutter/material.dart';

import '../widgets/property_type_selector.dart';

class PropertyHomeScreen extends StatelessWidget {
  const PropertyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Property rentals')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Search by area or property type',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          SizedBox(height: 24),
          PropertyTypeSelector(),
          SizedBox(height: 24),
          Text('Featured properties will appear here.'),
        ],
      ),
    );
  }
}
