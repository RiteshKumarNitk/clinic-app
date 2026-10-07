import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
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
          backgroundColor: ClinicColors.background,
          flexibleSpace: clinic.coverImageUrl == null
              ? null
              : FlexibleSpaceBar(
                  background: Image.network(
                    clinic.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const ColoredBox(color: ClinicColors.primarySoft),
                  ),
                ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            ClinicSpacing.gutter,
            ClinicSpacing.sm,
            ClinicSpacing.gutter,
            ClinicSpacing.xxl,
          ),
          sliver: SliverList.list(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EntityAvatar(
                    label: clinic.name,
                    imageUrl: clinic.logoUrl,
                    size: 64,
                    icon: Icons.local_hospital_outlined,
                  ),
                  const SizedBox(width: ClinicSpacing.lg),
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
                              StatusBadge(
                                label: type,
                                color: ClinicColors.accent,
                                background: ClinicColors.accentSoft,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (clinic.tagline != null) ...[
                const SizedBox(height: ClinicSpacing.md),
                Text(clinic.tagline!, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: ClinicSpacing.xl),
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
                const SizedBox(height: ClinicSpacing.lg),
                _Panel(
                  title: 'About',
                  children: [
                    Text(clinic.about!, style: theme.textTheme.bodyLarge),
                  ],
                ),
              ],
              if (clinic.appointmentTypes.isNotEmpty) ...[
                const SizedBox(height: ClinicSpacing.lg),
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
                              color: ClinicColors.primary,
                            ),
                            label: Text('${t.name} · ${t.durationMinutes} min'),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
              const SizedBox(height: ClinicSpacing.xl),
              SectionHeader(title: 'Doctors (${clinic.doctors.length})'),
              if (clinic.doctors.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(ClinicSpacing.lg),
                    child: Text(
                      'No doctors are currently available at this clinic.',
                    ),
                  ),
                )
              else
                for (final d in clinic.doctors) ...[
                  DoctorCard(doctor: d),
                  const SizedBox(height: ClinicSpacing.md),
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
        padding: const EdgeInsets.all(ClinicSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: ClinicSpacing.sm),
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
        padding: const EdgeInsets.all(ClinicSpacing.gutter),
        children: const [
          SizedBox(height: 48),
          Row(
            children: [
              Skeleton(width: 64, height: 64, radius: 16),
              SizedBox(width: ClinicSpacing.lg),
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
          SizedBox(height: ClinicSpacing.xl),
          SkeletonCard(avatar: false, lines: 3),
          SizedBox(height: ClinicSpacing.xl),
          Skeleton(width: 120, height: 18),
          SizedBox(height: ClinicSpacing.md),
          SkeletonCard(),
          SizedBox(height: ClinicSpacing.md),
          SkeletonCard(),
        ],
      ),
    );
  }
}
