import 'package:flutter/material.dart';

Future<String?> showCancelReasonDialog(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancellation reason'),
      content: TextField(controller: controller, maxLines: 3),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Submit'),
        ),
      ],
    ),
  );
}
