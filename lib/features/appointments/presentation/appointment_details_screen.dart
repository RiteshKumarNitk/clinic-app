import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/dependencies.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/clinic_time.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../data/appointment_models.dart';
import '../data/appointment_repository.dart';
import 'appointment_card.dart';
import 'booking_widgets.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  const AppointmentDetailsScreen({
    super.key,
    required this.organizationId,
    required this.appointmentId,
    this.preview,
  });

  final String organizationId;
  final String appointmentId;

  /// The list row, if we came from a list — its clinic name is reused.
  final Appointment? preview;

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  int _reloadKey = 0;

  Future<Appointment> _load() async {
    final a = await context.read<AppointmentRepository>().detail(
      organizationId: widget.organizationId,
      appointmentId: widget.appointmentId,
    );
    final p = widget.preview;
    return a.clinicName == null && p != null
        ? a.withClinic(name: p.clinicName, slug: p.clinicSlug)
        : a;
  }

  Future<void> _cancel(Appointment a) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          ClinicSpacing.gutter,
          0,
          ClinicSpacing.gutter,
          ClinicSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cancel this appointment?',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: ClinicSpacing.sm),
            Text(
              '${a.doctorName ?? 'Your visit'} · '
              '${ClinicTime.date(a.scheduledStart, a.timezone)}',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: ClinicSpacing.xl),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ClinicColors.danger,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel appointment'),
            ),
            const SizedBox(height: ClinicSpacing.sm),
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep it'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final changed = context.read<Dependencies>().appointmentsChanged;
    try {
      await context.read<AppointmentRepository>().cancel(
        organizationId: a.organizationId,
        appointmentId: a.id,
        reason: 'Cancelled by patient in app',
      );
      changed.bump();
      messenger.showSnackBar(
        const SnackBar(content: Text('Appointment cancelled.')),
      );
      setState(() => _reloadKey++);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            friendlyMessage(
              e,
              fallback:
                  "We couldn't cancel this appointment. Please try again.",
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointment')),
      body: AsyncView<Appointment>(
        key: ValueKey(_reloadKey),
        load: _load,
        errorMessage: "We couldn't load this appointment.",
        loading: const SkeletonList(count: 2, lines: 4),
        builder: (context, a, reload) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: reload,
                child: ListView(
                  padding: const EdgeInsets.all(ClinicSpacing.gutter),
                  children: [_Body(appointment: a)],
                ),
              ),
            ),
            if (a.status.isActive)
              BottomAction(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (a.hasQueue && a.status.isActive) ...[
                      FilledButton.icon(
                        onPressed: () => context.push(
                          '${Routes.queue(a.id)}?org=${a.organizationId}',
                        ),
                        icon: const Icon(Icons.confirmation_number_outlined),
                        label: const Text('View live queue'),
                      ),
                      const SizedBox(height: ClinicSpacing.sm),
                    ],
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: ClinicColors.danger,
                      ),
                      onPressed: () => _cancel(a),
                      child: const Text('Cancel appointment'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final theme = Theme.of(context);
    final location = [
      a.locationName,
      a.locationAddress,
      a.locationCity,
    ].whereType<String>().join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                a.doctorName ?? 'Appointment',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            statusBadge(a.status),
          ],
        ),
        if (a.clinicName != null) ...[
          const SizedBox(height: 4),
          Text(a.clinicName!, style: theme.textTheme.bodyLarge),
        ],
        const SizedBox(height: ClinicSpacing.lg),
        if (a.hasQueue && a.tokenNumber != null) ...[
          Container(
            padding: const EdgeInsets.all(ClinicSpacing.lg),
            decoration: BoxDecoration(
              color: ClinicColors.primary,
              borderRadius: BorderRadius.circular(ClinicRadius.lg),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: ClinicSpacing.md),
                const Expanded(
                  child: Text(
                    'Your token',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '#${a.tokenNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: ClinicSpacing.lg),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClinicSpacing.lg,
              vertical: ClinicSpacing.sm,
            ),
            child: Column(
              children: [
                SummaryRow(
                  icon: Icons.event_outlined,
                  label: 'Date',
                  value: ClinicTime.date(a.scheduledStart, a.timezone),
                ),
                SummaryRow(
                  icon: Icons.schedule_rounded,
                  label: a.isToken ? 'Queue starts' : 'Time',
                  value: ClinicTime.time(a.scheduledStart, a.timezone),
                ),
                if (a.appointmentTypeName != null)
                  SummaryRow(
                    icon: Icons.medical_information_outlined,
                    label: 'Visit',
                    value: a.appointmentTypeName!,
                  ),
                if (a.isToken)
                  const SummaryRow(
                    icon: Icons.confirmation_number_outlined,
                    label: 'Booking',
                    value: 'Same-day token',
                  ),
                if (location.isNotEmpty)
                  SummaryRow(
                    icon: Icons.place_outlined,
                    label: 'Location',
                    value: location,
                  ),
                if (a.patientName != null)
                  SummaryRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Patient',
                    value: a.patientName!,
                  ),
                if (a.reason != null)
                  SummaryRow(
                    icon: Icons.notes_rounded,
                    label: 'Reason',
                    value: a.reason!,
                  ),
                if (a.cancellationReason != null &&
                    a.status == AppointmentStatus.cancelled)
                  SummaryRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Cancelled',
                    value: a.cancellationReason!,
                  ),
              ],
            ),
          ),
        ),
        if (a.clinicSlug != null) ...[
          const SizedBox(height: ClinicSpacing.md),
          OutlinedButton.icon(
            onPressed: () => context.push(Routes.clinic(a.clinicSlug!)),
            icon: const Icon(Icons.local_hospital_outlined),
            label: const Text('View clinic'),
          ),
        ],
      ],
    );
  }
}
