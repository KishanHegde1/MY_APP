import 'package:flutter/material.dart';

class LandDetailsScreen extends StatelessWidget {
  const LandDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Land details')),
      body: const Center(
        child: Text('Land size, location, and rent will appear here.'),
      ),
    );
  }
}
