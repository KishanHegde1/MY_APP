import 'package:flutter/material.dart';

class RoomBookingScreen extends StatelessWidget {
  const RoomBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book room')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Booking dates and price summary will appear here.'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // TODO: Create a room booking through the backend.
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
