import 'package:flutter/material.dart';

import '../widgets/profile_placeholder_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePlaceholderPage(
      title: 'Settings',
      description:
          'Account, privacy, appearance, and notification settings will appear here.',
    );
  }
}
