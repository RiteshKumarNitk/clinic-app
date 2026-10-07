import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../../core/utils/external_actions.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../doctors/presentation/doctor_card.dart';
import '../data/clinic_models.dart';
import '../data/clinic_repository.dart';
import 'clinic_card.dart';

class ClinicDetailsScreen extends StatelessWidget {
  const ClinicDetailsScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<ClinicRepository>();
    return Scaffold(
      body: AsyncView<ClinicDetail>(
        load: () => repo.detail(slug),
        errorMessage: "We couldn't load this clinic.",
        loading: const _ClinicSkeleton(),
        builder: (context, clinic, reload) => RefreshIndicator(
          onRefresh: () async {
            await repo.detail(slug, refresh: true);
            await reload();
          },
          child: _ClinicBody(clinic: clinic),
        ),
      ),
    );
  }
}

class _ClinicBody extends StatelessWidget {
  const _ClinicBody({required this.clinic});

  final ClinicDetail clinic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = orgTypeLabel(clinic.orgType);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: clinic.coverImageUrl != null ? 200 : 0,
          backgroundColor: CityCareColors.background,
          flexibleSpace: clinic.coverImageUrl == null
              ? null
              : FlexibleSpaceBar(
                  background: Image.network(
                    clinic.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: CityCareColors.primarySoft),
                  ),
                ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            CityCareSpacing.gutter,
            CityCareSpacing.sm,
            CityCareSpacing.gutter,
            CityCareSpacing.xxl,
          ),
          sliver: SliverList.list(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CityCareAvatar(
                    label: clinic.name,
                    imageUrl: clinic.logoUrl,
                    size: 64,
                    icon: Icons.local_hospital_outlined,
                  ),
                  const SizedBox(width: CityCareSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(clinic.name, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (clinic.verification ==
                                VerificationStatus.verified)
                              const VerifiedBadge(),
                            if (type != null)
                              CityCareStatusBadge(
                                label: type,
                                color: CityCareColors.accent,
                                background: CityCareColors.accentSoft,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (clinic.tagline != null) ...[
                const SizedBox(height: CityCareSpacing.md),
                Text(clinic.tagline!, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: CityCareSpacing.lg),
              _ClinicActions(clinic: clinic),
              const SizedBox(height: CityCareSpacing.xl),
              _Panel(
                title: 'Contact & location',
                children: [
                  for (final l in clinic.locations) ...[
                    InfoRow(
                      icon: Icons.place_outlined,
                      text: l.address.isEmpty
                          ? l.name
                          : '${l.name}\n${l.address}',
                    ),
                    if (l.phone != null)
                      InfoRow(icon: Icons.call_outlined, text: l.phone!),
                  ],
                  if (clinic.publicPhone != null)
                    InfoRow(
                      icon: Icons.call_outlined,
                      text: clinic.publicPhone!,
                    ),
                  if (clinic.publicEmail != null)
                    InfoRow(
                      icon: Icons.mail_outline_rounded,
                      text: clinic.publicEmail!,
                    ),
                  if (clinic.website != null)
                    InfoRow(
                      icon: Icons.language_rounded,
                      text: clinic.website!,
                    ),
                ],
              ),
              if (clinic.about != null) ...[
                const SizedBox(height: CityCareSpacing.lg),
                _Panel(
                  title: 'About',
                  children: [
                    Text(clinic.about!, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ],
              if (clinic.appointmentTypes.isNotEmpty) ...[
                const SizedBox(height: CityCareSpacing.lg),
                _Panel(
                  title: 'Appointment types',
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in clinic.appointmentTypes)
                          Chip(
                            avatar: const Icon(
                              Icons.schedule_rounded,
                              size: 16,
                              color: CityCareColors.primary,
                            ),
                            label: Text('${t.name} · ${t.durationMinutes} min'),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
              const SizedBox(height: CityCareSpacing.xl),
              CityCareSectionHeader(
                title: 'Doctors (${clinic.doctors.length})',
              ),
              if (clinic.doctors.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(CityCareSpacing.lg),
                    child: Text(
                      'No doctors are currently available at this clinic.',
                    ),
                  ),
                )
              else
                for (final d in clinic.doctors) ...[
                  DoctorCard(doctor: d),
                  const SizedBox(height: CityCareSpacing.md),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(CityCareSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: CityCareSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ClinicSkeleton extends StatelessWidget {
  const _ClinicSkeleton();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(CityCareSpacing.gutter),
        children: const [
          SizedBox(height: 48),
          Row(
            children: [
              Skeleton(width: 64, height: 64, radius: 16),
              SizedBox(width: CityCareSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton(width: 200, height: 20),
                    SizedBox(height: 10),
                    Skeleton(width: 90, height: 14),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: CityCareSpacing.xl),
          CityCareSkeletonCard(avatar: false, lines: 3),
          SizedBox(height: CityCareSpacing.xl),
          Skeleton(width: 120, height: 18),
          SizedBox(height: CityCareSpacing.md),
          CityCareSkeletonCard(),
          SizedBox(height: CityCareSpacing.md),
          CityCareSkeletonCard(),
        ],
      ),
    );
  }
}

/// Call · Directions · Email · Website — whatever the clinic published.
class _ClinicActions extends StatelessWidget {
  const _ClinicActions({required this.clinic});

  final ClinicDetail clinic;

  @override
  Widget build(BuildContext context) {
    final branch = clinic.locations.firstOrNull;
    final phone = clinic.publicPhone ?? branch?.phone;
    final actions = <(IconData, String, VoidCallback)>[
      if (phone != null)
        (
          Icons.call_rounded,
          'Call',
          () => ExternalActions.call(context, phone),
        ),
      if (branch != null)
        (
          Icons.directions_rounded,
          'Directions',
          () => ExternalActions.directions(
            context,
            label: clinic.name,
            address: branch.address.isEmpty ? null : branch.address,
            latitude: branch.latitude,
            longitude: branch.longitude,
          ),
        ),
      if (clinic.publicEmail != null)
        (
          Icons.mail_outline_rounded,
          'Email',
          () => ExternalActions.email(context, clinic.publicEmail!),
        ),
      if (clinic.website != null)
        (
          Icons.language_rounded,
          'Website',
          () => ExternalActions.website(context, clinic.website!),
        ),
    ];
    if (actions.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (final (i, a) in actions.indexed) ...[
          if (i > 0) const SizedBox(width: CityCareSpacing.sm),
          Expanded(
            child: Material(
              color: CityCareColors.surface,
              borderRadius: BorderRadius.circular(CityCareRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(CityCareRadius.md),
                onTap: a.$3,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(CityCareRadius.md),
                    border: Border.all(color: CityCareColors.border),
                  ),
                  child: Column(
                    children: [
                      Icon(a.$1, color: CityCareColors.primary),
                      const SizedBox(height: 4),
                      Text(
                        a.$2,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
