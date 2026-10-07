import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/clinic_time.dart';
import '../../../core/widgets/state_views.dart';
import '../data/doctor_models.dart';

/// Doctor card. [showClinic] adds the clinic line in cross-clinic search.
class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, this.showClinic = false});

  final DoctorSummary doctor;
  final bool showClinic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fee = formatFee(doctor.consultationFeeMinor);
    final facts = [
      if (doctor.yearsOfExperience != null)
        '${doctor.yearsOfExperience} yrs exp',
      if (doctor.languages.isNotEmpty) doctor.languages.join(', '),
      ?fee,
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.doctor(doctor.id)),
        child: Padding(
          padding: const EdgeInsets.all(CityCareSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CityCareAvatar(
                label: doctor.displayName,
                imageUrl: doctor.photoUrl,
                circle: true,
              ),
              const SizedBox(width: CityCareSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.displayName,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (doctor.specialty != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialty!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: CityCareColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (showClinic && doctor.clinic != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        doctor.clinic!.name,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (facts.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        facts.join('  ·  '),
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (doctor.bookingMode.offersTokens) ...[
                      const SizedBox(height: 8),
                      const CityCareStatusBadge(
                        label: 'Same-day tokens',
                        icon: Icons.confirmation_number_outlined,
                        color: CityCareColors.warning,
                        background: CityCareColors.warningSoft,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: CityCareSpacing.sm),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: CityCareColors.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
