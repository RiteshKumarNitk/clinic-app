import 'package:flutter/material.dart';

import '../../core/widgets/citycare.dart';

/// The CityCare mark in a soft rounded tile (app-icon style).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.inverted = false});

  final double size;

  /// White tile for gradient backgrounds.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: inverted ? Colors.white : const Color(0xFFE6F2FA),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: CityCareLogo(size: size * 0.66),
    );
  }
}
