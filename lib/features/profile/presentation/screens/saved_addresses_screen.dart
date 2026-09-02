import 'package:flutter/material.dart';

import '../widgets/profile_placeholder_page.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProfilePlaceholderPage(
      title: 'Saved addresses',
      description: 'Saved pickup, home, and work addresses will appear here.',
    );
  }
}
