import 'package:flutter/material.dart';

import '../widgets/provider_placeholder_page.dart';

class ProviderEarningsScreen extends StatelessWidget {
  const ProviderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderPlaceholderPage(
      title: 'Provider earnings',
      description:
          'Verified earnings and payout summaries will appear after integration.',
    );
  }
}
