import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/google_auth_gateway.dart';
import '../../core/errors/api_exception.dart';
import 'google_button.dart';

/// Full-page "sign in to see this" state for guest-facing tabs.
class SignInPromptView extends StatelessWidget {
  const SignInPromptView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  Future<void> _signIn(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<AuthController>().signInWithGoogle();
    } on GoogleSignInCancelled {
      // closed the picker
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            friendlyMessage(e, fallback: "We couldn't sign you in. Try again."),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().busy;
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ClinicSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: ClinicGradients.hero,
                borderRadius: BorderRadius.circular(30),
                boxShadow: ClinicShadows.soft,
              ),
              child: Icon(icon, color: Colors.white, size: 44),
            ),
            const SizedBox(height: ClinicSpacing.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: ClinicSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
            ),
            const SizedBox(height: ClinicSpacing.xl),
            GoogleButton(
              filled: true,
              busy: busy,
              onPressed: () => _signIn(context),
            ),
          ],
        ),
      ),
    );
  }
}
