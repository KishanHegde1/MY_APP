import 'package:flutter/material.dart';

import '../widgets/settings_placeholder_page.dart';

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPlaceholderPage(
      title: 'Privacy settings',
      description: 'Privacy and account-security controls will appear here.',
    );
  }
}
