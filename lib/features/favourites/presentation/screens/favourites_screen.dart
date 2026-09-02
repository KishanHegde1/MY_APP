import 'package:flutter/material.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Favourites')),
    body: const Center(
      child: Text('Saved vehicles, rooms, and properties will appear here.'),
    ),
  );
}
