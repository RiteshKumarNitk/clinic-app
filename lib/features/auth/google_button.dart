import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// "Continue with Google" — the app's only sign-in button. White surface with
/// a multicolour "G" so it reads as Google on both light and gradient
/// backgrounds.
class GoogleButton extends StatelessWidget {
  const GoogleButton({
    super.key,
    required this.onPressed,
    this.busy = false,
    this.filled = false,
  });

  final VoidCallback? onPressed;
  final bool busy;

  /// Dark filled variant for white backgrounds.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? ClinicColors.ink : Colors.white;
    final fg = filled ? Colors.white : ClinicColors.ink;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(ClinicRadius.md),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(ClinicRadius.md),
          onTap: busy ? null : onPressed,
          child: Center(
            child: busy
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: fg,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _GoogleG(),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          'Continue with Google',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// A four-colour "G" built from text — no trademarked image asset bundled.
class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: ShaderMask(
        shaderCallback: (r) => const SweepGradient(
          colors: [
            Color(0xFF4285F4),
            Color(0xFF34A853),
            Color(0xFFFBBC05),
            Color(0xFFEA4335),
            Color(0xFF4285F4),
          ],
        ).createShader(r),
        child: const Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
