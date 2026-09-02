import 'package:flutter/material.dart';

class ContactOwnerScreen extends StatelessWidget {
  const ContactOwnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact owner')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Your message will be sent to the verified listing owner.',
          ),
          const SizedBox(height: 16),
          const TextField(
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              // TODO: Submit the property inquiry to the backend.
            },
            child: const Text('Send inquiry'),
          ),
        ],
      ),
    );
  }
}
