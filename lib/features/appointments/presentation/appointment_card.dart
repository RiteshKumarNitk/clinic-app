import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/clinic_time.dart';
import '../../../core/widgets/state_views.dart';
import '../data/appointment_models.dart';

/// Status pill colours, shared by list and details.
StatusBadge statusBadge(AppointmentStatus s) {
  final (fg, bg) = switch (s) {
    AppointmentStatus.confirmed || AppointmentStatus.checkedIn => (
      ClinicColors.success,
      ClinicColors.successSoft,
    ),
    AppointmentStatus.requested ||
    AppointmentStatus.waiting ||
    AppointmentStatus.inConsultation => (
      ClinicColors.accent,
      ClinicColors.accentSoft,
    ),
    AppointmentStatus.cancelled ||
    AppointmentStatus.noShow => (ClinicColors.danger, ClinicColors.dangerSoft),
    _ => (ClinicColors.inkMuted, ClinicColors.skeleton),
  };
  return StatusBadge(label: s.label, color: fg, background: bg);
}

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final theme = Theme.of(context);
    final local = ClinicTime.local(a.scheduledStart, a.timezone);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.push(Routes.appointment(a.organizationId, a.id), extra: a),
        child: Padding(
          padding: const EdgeInsets.all(ClinicSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: a.status.isActive
                      ? ClinicColors.primarySoft
                      : ClinicColors.background,
                  borderRadius: BorderRadius.circular(ClinicRadius.md),
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMM').format(local).toUpperCase(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: ClinicColors.primaryDark,
                      ),
                    ),
                    Text(
                      '${local.day}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: ClinicColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: ClinicSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.doctorName ?? 'Appointment',
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        statusBadge(a.status),
                      ],
                    ),
                    if (a.clinicName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        a.clinicName!,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      [
                        DateFormat('EEE').format(local),
                        a.isToken
                            ? 'Token #${a.tokenNumber ?? '–'}'
                            : ClinicTime.time(a.scheduledStart, a.timezone),
                        ?a.appointmentTypeName,
                      ].join('  ·  '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
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
