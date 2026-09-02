import 'package:flutter/material.dart';

import '../widgets/chat_placeholder_page.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChatPlaceholderPage(
      title: 'Messages',
      description:
          'Booking-related conversations will appear after chat integration.',
    );
  }
}
