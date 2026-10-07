import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import 'brand_mark.dart';

/// Branded splash while the saved session is restored (held for a moment so
/// it never flashes). The router replaces it when restoration settles.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..forward();

  late final _mark = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, 0.65, curve: Curves.easeOutBack),
  );
  late final _text = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.35, 1, curve: Curves.easeOutCubic),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: ClinicGradients.hero),
          child: Stack(
            children: [
              const Positioned(top: -90, right: -70, child: _Ring(size: 260)),
              const Positioned(
                bottom: -120,
                left: -80,
                child: _Ring(size: 300),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _mark,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: ClinicShadows.lifted,
                        ),
                        child: const BrandMark(size: 96, inverted: true),
                      ),
                    ),
                    const SizedBox(height: ClinicSpacing.xl),
                    FadeTransition(
                      opacity: _text,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(0, 0.4),
                          end: Offset.zero,
                        ).animate(_text),
                        child: const Column(
                          children: [
                            Text(
                              'Clinic',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Find & book trusted healthcare',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 72,
                child: Center(
                  child: SizedBox(
                    width: 88,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        minHeight: 4,
                        color: Colors.white,
                        backgroundColor: Color(0x40FFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faint decorative ring for depth on gradient surfaces.
class _Ring extends StatelessWidget {
  const _Ring({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.10),
        width: 28,
      ),
    ),
  );
}
