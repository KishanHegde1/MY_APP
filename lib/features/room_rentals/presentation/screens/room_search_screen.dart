import 'package:flutter/material.dart';

import '../widgets/room_search_prompt.dart';

class RoomSearchScreen extends StatelessWidget {
  const RoomSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search rooms')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            RoomSearchPrompt(),
            SizedBox(height: 24),
            Expanded(
              child: Center(
                child: Text('Room search results will appear here.'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
