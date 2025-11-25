import 'package:flutter/material.dart';

/// Displays a SnackBar with the given [message].
void showSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
}) {
  final snackBar = SnackBar(
    content: Text(message),
    backgroundColor: backgroundColor ?? Colors.redAccent,
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  // Hide any existing snackbar before showing a new one
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snackBar);
}
