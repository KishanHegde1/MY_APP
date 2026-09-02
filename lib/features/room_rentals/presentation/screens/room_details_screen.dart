import 'package:flutter/material.dart';

class RoomDetailsScreen extends StatelessWidget {
  const RoomDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room details')),
      body: const Center(
        child: Text('Room photos, amenities, and rent will appear here.'),
      ),
    );
  }
}
