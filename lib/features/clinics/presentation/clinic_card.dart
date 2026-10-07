import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/citycare.dart';
import '../../../core/widgets/state_views.dart';
import '../data/clinic_models.dart';

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) => CityCareStatusBadge(
    label: 'Verified',
    icon: Icons.verified_rounded,
    color: onDark ? CityCareColors.navy : CityCareColors.success,
    background: onDark ? CityCareColors.lime : CityCareColors.successSoft,
  );
}

String _distance(double km) => km < 1
    ? '${(km * 1000).round()} m away'
    : '${km.toStringAsFixed(1)} km away';

/// Location line: distance (near me) or cities. Only what the API returned.
String? _where(ClinicSummary c) {
  final parts = [
    if (c.distanceKm != null) _distance(c.distanceKm!),
    if (c.cities.isNotEmpty) c.cities.join(' · '),
  ];
  return parts.isEmpty ? null : parts.join('  ·  ');
}

String? _doctors(ClinicSummary c) => c.doctorCount <= 0
    ? null
    : '${c.doctorCount} ${c.doctorCount == 1 ? 'doctor' : 'doctors'}';

/// Clinic card for lists.
class ClinicCard extends StatelessWidget {
  const ClinicCard({super.key, required this.clinic, this.compact = false});

  final ClinicSummary clinic;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = orgTypeLabel(clinic.orgType);
    final where = _where(clinic);
    final doctors = _doctors(clinic);

    return CityCareCard(
      onTap: () => context.push(Routes.clinic(clinic.slug)),
      padding: const EdgeInsets.all(CityCareSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CityCareAvatar(
            label: clinic.name,
            imageUrl: clinic.logoUrl,
            size: 56,
            icon: Icons.local_hospital_rounded,
          ),
          const SizedBox(width: CityCareSpacing.md),
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
                      if (clinic.verification == VerificationStatus.verified)
                        const VerifiedBadge(),
                      if (type != null)
                        CityCareStatusBadge(
                          label: type,
                          color: CityCareColors.primaryDark,
                          background: CityCareColors.primarySoft,
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
                if (where != null || doctors != null) ...[
                  const SizedBox(height: CityCareSpacing.sm),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      if (where != null)
                        _Meta(icon: Icons.place_outlined, text: where),
                      if (doctors != null)
                        _Meta(
                          icon: Icons.medical_services_outlined,
                          text: doctors,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: CityCareSpacing.sm),
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: CityCareColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: CityCareColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.onDark = false});

  final IconData icon;
  final String text;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final color = onDark ? Colors.white : CityCareColors.inkMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12.5, color: color, height: 1.3)),
      ],
    );
  }
}

/// Large blue hero card for the first clinic on Home.
class FeaturedClinicCard extends StatelessWidget {
  const FeaturedClinicCard({super.key, required this.clinic});

  final ClinicSummary clinic;

  @override
  Widget build(BuildContext context) {
    final where = _where(clinic);
    final doctors = _doctors(clinic);
    final type = orgTypeLabel(clinic.orgType);
    return Container(
      decoration: BoxDecoration(
        gradient: CityCareGradients.hero,
        borderRadius: BorderRadius.circular(CityCareRadius.xl),
        boxShadow: CityCareShadows.soft,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(CityCareRadius.xl),
          onTap: () => context.push(Routes.clinic(clinic.slug)),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 22,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(CityCareSpacing.xl - 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              CityCareRadius.md,
                            ),
                          ),
                          child: CityCareAvatar(
                            label: clinic.name,
                            imageUrl: clinic.logoUrl,
                            size: 46,
                            icon: Icons.local_hospital_rounded,
                          ),
                        ),
                        const SizedBox(width: CityCareSpacing.md),
                        Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const Spacer(),
                        if (clinic.verification == VerificationStatus.verified)
                          const VerifiedBadge(onDark: true),
                      ],
                    ),
                    const SizedBox(height: CityCareSpacing.lg),
                    Text(
                      clinic.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (type != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: CityCareSpacing.md),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        if (where != null)
                          _Meta(
                            icon: Icons.place_outlined,
                            text: where,
                            onDark: true,
                          ),
                        if (doctors != null)
                          _Meta(
                            icon: Icons.medical_services_outlined,
                            text: doctors,
                            onDark: true,
                          ),
                      ],
                    ),
                    const SizedBox(height: CityCareSpacing.lg),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          CityCareRadius.pill,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'View clinic',
                            style: TextStyle(
                              color: CityCareColors.navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: CityCareColors.lime,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_outward_rounded,
                              size: 17,
                              color: CityCareColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
