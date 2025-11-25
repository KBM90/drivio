import 'package:flutter/material.dart';
import 'package:drivio_app/common/constants/routes.dart';
import 'package:drivio_app/common/helpers/custom_exceptions.dart';
import 'package:drivio_app/common/helpers/snack_bar_helper.dart';

void handleAppError(BuildContext context, dynamic e) {
  if (e is UnauthorizedException) {
    // Clear auth state if needed and redirect to login
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  } else if (e is ForbiddenException) {
    showSnackBar(context, e.message, backgroundColor: Colors.orange);
  } else if (e is NotFoundException) {
    showSnackBar(context, e.message, backgroundColor: Colors.red);
  } else if (e is ServerErrorException) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Server Error'),
            content: Text(e.message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  } else {
    // Fallback for unexpected errors
    showSnackBar(context, e.toString(), backgroundColor: Colors.red);
  }
}
