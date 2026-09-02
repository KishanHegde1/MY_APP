import 'package:flutter/material.dart';

import '../widgets/payments_placeholder_page.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PaymentsPlaceholderPage(
      title: 'Transaction history',
      description: 'Verified payment transactions will appear here.',
    );
  }
}
