import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/google_auth_gateway.dart';
import '../../core/errors/api_exception.dart';
import 'brand_mark.dart';

/// The only sign-in surface of the app: Continue with Google. There is no
/// email/password path for patients.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signIn(BuildContext context) async {
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.signInWithGoogle();
      // The router moves to Home on its own once the state flips.
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
    return Scaffold(
      backgroundColor: ClinicColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          // Scrolls on short screens instead of overflowing; fills tall ones.
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: ClinicSpacing.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(flex: 2),
                    const BrandMark(size: 64),
                    const SizedBox(height: ClinicSpacing.xl),
                    Text(
                      'Find and book\ntrusted healthcare',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: ClinicSpacing.md),
                    Text(
                      'Discover clinics and doctors near you, book a visit in a few '
                      'taps, and follow your place in the queue live.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: ClinicColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: ClinicSpacing.xl),
                    const _Benefit(
                      icon: Icons.verified_user_outlined,
                      text: 'Real clinics and doctors',
                    ),
                    const _Benefit(
                      icon: Icons.event_available_outlined,
                      text: 'Live appointment availability',
                    ),
                    const _Benefit(
                      icon: Icons.confirmation_number_outlined,
                      text: 'Same-day tokens and live queue',
                    ),
                    const Spacer(flex: 3),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: busy ? null : () => _signIn(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: ClinicColors.ink,
                          disabledBackgroundColor: ClinicColors.ink.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _GoogleG(),
                                  SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'Continue with Google',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: ClinicSpacing.md),
                    Center(
                      child: Text(
                        'We use your Google account only to sign you in.',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: ClinicSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ClinicColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 19, color: ClinicColors.primary),
          ),
          const SizedBox(width: ClinicSpacing.md),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}

/// A plain white "G" badge — avoids bundling Google's trademarked logo asset.
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: ClinicColors.ink,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}
