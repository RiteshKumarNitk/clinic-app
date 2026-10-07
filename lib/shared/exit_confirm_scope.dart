import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/theme.dart';

/// Wraps a top-level screen (tabs, login) so the system Back button asks
/// before closing the app instead of exiting immediately. Inner screens are
/// unaffected — Back still pops them as usual.
class ExitConfirmScope extends StatelessWidget {
  const ExitConfirmScope({super.key, required this.child});

  final Widget child;

  static Future<void> _confirmExit(BuildContext context) async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.exit_to_app_rounded,
          color: ClinicColors.primary,
          size: 32,
        ),
        title: const Text('Close Clinic?'),
        content: const Text('Are you sure you want to exit the app?'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (exit == true) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: child,
    );
  }
}
