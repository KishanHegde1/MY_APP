import 'package:flutter/material.dart';

import '../widgets/support_placeholder_page.dart';

class CreateSupportTicketScreen extends StatelessWidget {
  const CreateSupportTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SupportPlaceholderPage(
      title: 'Contact support',
      description:
          'A validated support request form will be implemented in this view.',
    );
  }
}
