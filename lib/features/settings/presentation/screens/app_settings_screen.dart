import 'package:flutter/material.dart';

import '../widgets/settings_placeholder_page.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsPlaceholderPage(
      title: 'App settings',
      description:
          'Theme, language, permissions, and notification controls will appear here.',
    );
  }
}
