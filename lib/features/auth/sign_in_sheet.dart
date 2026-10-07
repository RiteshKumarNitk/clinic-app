import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/google_auth_gateway.dart';
import '../../core/errors/api_exception.dart';
import 'google_button.dart';

/// Guests can browse everything public; personal actions (booking, tokens,
/// appointments, queue) come through here first.
///
/// Returns true when the user is — or has just become — signed in.
Future<bool> requireSignIn(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  if (context.read<AuthController>().isAuthenticated) return true;
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: CityCareColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _SignInSheet(title: title, message: message),
  );
  return ok ?? false;
}

class _SignInSheet extends StatefulWidget {
  const _SignInSheet({required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> {
  String? _error;

  Future<void> _signIn() async {
    final auth = context.read<AuthController>();
    setState(() => _error = null);
    try {
      await auth.signInWithGoogle();
      if (mounted && auth.isAuthenticated) Navigator.pop(context, true);
    } on GoogleSignInCancelled {
      // Picker closed — stay on the sheet.
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = friendlyMessage(
            e,
            fallback: "We couldn't sign you in. Please try again.",
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().busy;
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CityCareColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: CityCareSpacing.xl),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                gradient: CityCareGradients.hero,
                borderRadius: BorderRadius.circular(22),
                boxShadow: CityCareShadows.soft,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: CityCareSpacing.lg),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: CityCareSpacing.sm),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 15),
            ),
            if (_error != null) ...[
              const SizedBox(height: CityCareSpacing.md),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: CityCareColors.danger),
              ),
            ],
            const SizedBox(height: CityCareSpacing.xl),
            GoogleButton(onPressed: _signIn, busy: busy, filled: true),
            const SizedBox(height: CityCareSpacing.sm),
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context, false),
              child: const Text('Keep browsing'),
            ),
          ],
        ),
      ),
    );
  }
}
