import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'brand_mark.dart';

/// Shown while the stored session is being restored. The router replaces it
/// as soon as [AuthController.restore] settles.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: ClinicColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandMark(size: 76, inverted: true),
            SizedBox(height: ClinicSpacing.lg),
            Text(
              'Clinic',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: ClinicSpacing.xxl),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
