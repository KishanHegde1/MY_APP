import 'package:flutter/material.dart';

import '../widgets/provider_placeholder_page.dart';

class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderPlaceholderPage(
      title: 'My listings',
      description: 'Published and draft provider listings will appear here.',
    );
  }
}
