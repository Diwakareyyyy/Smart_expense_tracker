import 'package:flutter/material.dart';

/// Shows a centered popup message (replaces snackbars).
void showMessageDialog(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onOk,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(
            title == 'Error' ? Icons.error_outline : Icons.check_circle_outline,
            color: title == 'Error' ? Colors.redAccent : Colors.green,
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 20)),
        ],
      ),
      content: Text(message, style: const TextStyle(fontSize: 15)),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onOk?.call();
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
