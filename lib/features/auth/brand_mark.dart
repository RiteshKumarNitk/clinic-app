import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The Clinic App mark: a rounded tile with a medical cross.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.inverted = false});

  final double size;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inverted ? Colors.white : ClinicColors.primary,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(
        Icons.local_hospital_rounded,
        size: size * 0.56,
        color: inverted ? ClinicColors.primary : Colors.white,
      ),
    );
  }
}
