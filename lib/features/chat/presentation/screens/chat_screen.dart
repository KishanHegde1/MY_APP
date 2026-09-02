import 'package:flutter/material.dart';

import '../widgets/chat_placeholder_page.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({this.roomId, super.key});

  final String? roomId;

  @override
  Widget build(BuildContext context) {
    return const ChatPlaceholderPage(
      title: 'Conversation',
      description:
          'Real-time messages and attachments will be implemented in this view.',
    );
  }
}
