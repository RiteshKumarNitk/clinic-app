import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/google_auth_gateway.dart';
import '../../core/errors/api_exception.dart';
import '../../core/widgets/citycare.dart';
import '../../shared/exit_confirm_scope.dart';
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
        value: SystemUiOverlayStyle.dark,
        child: Scaffold(
          body: CityCareBackground(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  padding: const EdgeInsets.all(CityCareSpacing.lg),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: box.maxHeight - CityCareSpacing.lg * 2,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _HeroPanel(),
                          const Spacer(),
                          const SizedBox(height: 48),
                          Text(
                            'Sign in to book visits and follow your queue '
                            'live, or look around first.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(height: CityCareSpacing.lg),
                          GoogleButton(
                            filled: true,
                            busy: busy,
                            onPressed: () => _signIn(context),
                          ),
                          const SizedBox(height: CityCareSpacing.md),
                          CityCareOutlinedButton(
                            label: 'Continue as guest',
                            onPressed: busy
                                ? null
                                : context
                                      .read<AuthController>()
                                      .continueAsGuest,
                          ),
                          const SizedBox(height: CityCareSpacing.md),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded blue panel with oversized type and a lime "book" badge.
class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 360;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 72),
          decoration: BoxDecoration(
            gradient: CityCareGradients.hero,
            borderRadius: BorderRadius.circular(CityCareRadius.xl + 4),
            boxShadow: CityCareShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CityCareWordmark(size: 32, onDark: true),
              const SizedBox(height: 36),
              Text(
                'Better\nhealthcare\nfor your city.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: narrow ? 34 : 42,
                  height: 1.06,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.6,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Discover trusted clinics and doctors, book appointments and '
                'follow live queues, all in one place.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(icon: Icons.local_hospital_rounded, label: 'Clinics'),
                  _Pill(
                    icon: Icons.event_available_rounded,
                    label: 'Live slots',
                  ),
                  _Pill(
                    icon: Icons.confirmation_number_rounded,
                    label: 'Queue tokens',
                  ),
                ],
              ),
            ],
          ),
        ),
        const Positioned(right: 18, bottom: -36, child: _BookBadge()),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(CityCareRadius.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular lime badge with text around an arrow — the brand's "book"
/// sticker. Decorative only.
class _BookBadge extends StatelessWidget {
  const _BookBadge();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: CityCareColors.lime,
          shape: BoxShape.circle,
          border: Border.all(color: CityCareColors.background, width: 5),
          boxShadow: CityCareShadows.soft,
        ),
        child: const Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(88, 88),
              painter: _CircleTextPainter('BOOK A VISIT • FIND CARE • '),
            ),
            Icon(
              Icons.arrow_outward_rounded,
              color: CityCareColors.navy,
              size: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleTextPainter extends CustomPainter {
  const _CircleTextPainter(this.text);

  final String text;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2 - 8;
    final center = size.center(Offset.zero);
    final step = 2 * math.pi / text.length;
    for (var i = 0; i < text.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: text[i],
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: CityCareColors.navy,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final angle = -math.pi / 2 + i * step;
      canvas.save();
      canvas.translate(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.rotate(angle + math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CircleTextPainter old) => old.text != text;
}
