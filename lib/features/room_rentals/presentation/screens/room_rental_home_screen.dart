import 'package:flutter/material.dart';

import '../widgets/room_search_prompt.dart';

class RoomRentalHomeScreen extends StatelessWidget {
  const RoomRentalHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room rentals')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RoomSearchPrompt(),
            SizedBox(height: 24),
            Text('Recommended rooms will appear here.'),
          ],
        ),
      ),
    );
  }
}
