import 'package:flutter/material.dart';

import '../widgets/wallet_placeholder_page.dart';

class AddMoneyScreen extends StatelessWidget {
  const AddMoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WalletPlaceholderPage(
      title: 'Add money',
      description:
          'Wallet top-up options will be enabled with the payment provider.',
    );
  }
}
