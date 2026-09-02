import 'package:flutter/material.dart';

import '../widgets/profile_placeholder_page.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePlaceholderPage(
      title: 'Help & support',
      description: 'Help topics and contact options will appear here.',
    );
  }
}
