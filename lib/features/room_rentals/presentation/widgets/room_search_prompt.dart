import 'package:flutter/material.dart';

class RoomSearchPrompt extends StatelessWidget {
  const RoomSearchPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return const TextField(
      decoration: InputDecoration(
        labelText: 'Search by area or landmark',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}
