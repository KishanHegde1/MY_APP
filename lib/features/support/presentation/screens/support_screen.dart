import 'package:flutter/material.dart';

import '../widgets/support_placeholder_page.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SupportPlaceholderPage(
      title: 'Support',
      description:
          'Help articles and existing support requests will appear here.',
    );
  }
}
