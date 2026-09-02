import 'package:flutter/material.dart';

import '../widgets/ride_option_card.dart';

class ChooseRideScreen extends StatelessWidget {
  const ChooseRideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a ride')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RideOptionCard(title: 'Bike', icon: Icons.two_wheeler_outlined),
          RideOptionCard(title: 'Auto', icon: Icons.electric_rickshaw_outlined),
          RideOptionCard(title: 'Car', icon: Icons.directions_car_outlined),
        ],
      ),
    );
  }
}
