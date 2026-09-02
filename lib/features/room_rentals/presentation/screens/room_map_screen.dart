import 'package:flutter/material.dart';

class RoomMapScreen extends StatelessWidget {
  const RoomMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rooms on map')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 72),
            SizedBox(height: 16),
            Text('Room map results will appear here.'),
          ],
        ),
      ),
    );
  }
}
