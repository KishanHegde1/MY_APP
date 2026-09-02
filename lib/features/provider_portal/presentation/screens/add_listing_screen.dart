import 'package:flutter/material.dart';

import '../widgets/provider_placeholder_page.dart';

class AddListingScreen extends StatelessWidget {
  const AddListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderPlaceholderPage(
      title: 'Add listing',
      description:
          'The guided listing form will be implemented in a future module.',
    );
  }
}
