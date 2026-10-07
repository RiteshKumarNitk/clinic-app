import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/state_views.dart';
import '../data/clinic_models.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key});

  @override
  Widget build(BuildContext context) => const StatusBadge(
    label: 'Verified',
    icon: Icons.verified_rounded,
    color: ClinicColors.success,
    background: ClinicColors.successSoft,
  );
}

/// Clinic card for lists. Shows only fields the backend actually returned.
class ClinicCard extends StatelessWidget {
  const ClinicCard({super.key, required this.clinic, this.compact = false});

  final ClinicSummary clinic;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = orgTypeLabel(clinic.orgType);
    final meta = [
      if (clinic.distanceKm != null) _distance(clinic.distanceKm!),
      if (clinic.cities.isNotEmpty) clinic.cities.join(' · '),
      if (clinic.doctorCount > 0)
        '${clinic.doctorCount} ${clinic.doctorCount == 1 ? 'doctor' : 'doctors'}',
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(Routes.clinic(clinic.slug)),
        child: Padding(
          padding: const EdgeInsets.all(ClinicSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EntityAvatar(
                label: clinic.name,
                imageUrl: clinic.logoUrl,
                icon: Icons.local_hospital_outlined,
              ),
              const SizedBox(width: ClinicSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (type != null ||
                        clinic.verification == VerificationStatus.verified) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (clinic.verification ==
                              VerificationStatus.verified)
                            const VerifiedBadge(),
                          if (type != null)
                            StatusBadge(
                              label: type,
                              color: ClinicColors.accent,
                              background: ClinicColors.accentSoft,
                            ),
                        ],
                      ),
                    ],
                    if (!compact && clinic.tagline != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        clinic.tagline!,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (meta.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 15,
                            color: ClinicColors.inkFaint,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              meta.join('  ·  '),
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: ClinicColors.inkFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _distance(double km) => km < 1
    ? '${(km * 1000).round()} m away'
    : '${km.toStringAsFixed(1)} km away';
