import 'package:flutter/material.dart';

import '../widgets/wallet_placeholder_page.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const WalletPlaceholderPage(
      title: 'Wallet',
      description:
          'Your verified balance and wallet activity will appear after integration.',
    );
  }
}
