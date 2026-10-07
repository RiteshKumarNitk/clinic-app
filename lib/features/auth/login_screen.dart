import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/google_auth_gateway.dart';
import '../../core/errors/api_exception.dart';
import '../../shared/exit_confirm_scope.dart';
import 'brand_mark.dart';
import 'google_button.dart';

/// Continue with Google, or browse as a guest. There is no email/password.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signIn(BuildContext context) async {
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.signInWithGoogle();
      // The router moves to the dashboard once the state flips.
    } on GoogleSignInCancelled {
      // The patient closed the picker; nothing to say.
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            friendlyMessage(
              e,
              fallback:
                  "We couldn't sign you in with Google. Please try again.",
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = context.watch<AuthController>().busy;
    final theme = Theme.of(context);

    return ExitConfirmScope(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          backgroundColor: ClinicColors.surface,
          body: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Hero(),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            24,
                            28,
                            24,
                            24 + MediaQuery.paddingOf(context).bottom,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome',
                                style: theme.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sign in to book visits and follow your queue '
                                'live, or look around first.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 15,
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(height: ClinicSpacing.xl),
                              GoogleButton(
                                filled: true,
                                busy: busy,
                                onPressed: () => _signIn(context),
                              ),
                              const SizedBox(height: ClinicSpacing.md),
                              OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : context
                                          .read<AuthController>()
                                          .continueAsGuest,
                                child: const Text('Continue as guest'),
                              ),
                              const SizedBox(height: ClinicSpacing.lg),
                              Text(
                                'Guests can browse clinics and doctors. '
                                'Booking needs a Google sign-in.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: ClinicGradients.hero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  BrandMark(size: 40, inverted: true),
                  SizedBox(width: 10),
                  Text(
                    'Clinic',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Find and book\ntrusted healthcare',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _Chip(icon: Icons.verified_rounded, label: 'Real clinics'),
                  _Chip(
                    icon: Icons.event_available_rounded,
                    label: 'Live slots',
                  ),
                  _Chip(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Queue tokens',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
