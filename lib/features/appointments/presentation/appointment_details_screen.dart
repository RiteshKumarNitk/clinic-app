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
import '../../../core/utils/external_actions.dart';
import '../../../core/widgets/citycare.dart';
import '../../clinics/data/clinic_models.dart';
import '../../clinics/data/clinic_repository.dart';
import '../../doctors/data/doctor_repository.dart';
import '../../records/data/records_models.dart';
import '../../records/data/records_repository.dart';
import '../../records/presentation/records_screen.dart';
import 'booking_draft.dart';
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

  /// Opens the slot picker for this doctor in "choose a new time" mode.
  Future<void> _reschedule(Appointment a) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final doctor = await context.read<DoctorRepository>().detail(a.doctorId);
      if (!mounted) return;
      final type = doctor.clinic.appointmentTypes
          .where((t) => t.id == a.appointmentTypeId)
          .firstOrNull;
      context.push(
        Routes.reschedule(a.organizationId, a.id),
        extra: BookingDraft(
          doctor: doctor,
          type: type,
          timezone: a.timezone,
          rescheduleOf: a,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            friendlyMessage(
              e,
              fallback: "We couldn't load this doctor's times. Try again.",
            ),
          ),
        ),
      );
    }
  }

  Future<void> _cancel(Appointment a) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          CityCareSpacing.gutter,
          0,
          CityCareSpacing.gutter,
          CityCareSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cancel this appointment?',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: CityCareSpacing.sm),
            Text(
              '${a.doctorName ?? 'Your visit'} · '
              '${ClinicTime.date(a.scheduledStart, a.timezone)}',
              style: Theme.of(ctx).textTheme.bodyMedium,
            ),
            const SizedBox(height: CityCareSpacing.xl),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: CityCareColors.danger,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Cancel appointment'),
            ),
            const SizedBox(height: CityCareSpacing.sm),
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
        loading: const CityCareLoading(count: 2, lines: 4),
        builder: (context, a, reload) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: reload,
                child: ListView(
                  padding: const EdgeInsets.all(CityCareSpacing.gutter),
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
                      CityCareButton(
                        onPressed: () => context.push(
                          '${Routes.queue(a.id)}?org=${a.organizationId}',
                        ),
                        icon: Icons.confirmation_number_outlined,
                        label: 'View live queue',
                      ),
                      const SizedBox(height: CityCareSpacing.sm),
                    ],
                    if (!a.isToken) ...[
                      OutlinedButton.icon(
                        onPressed: () => _reschedule(a),
                        icon: const Icon(Icons.update_rounded),
                        label: const Text('Change time'),
                      ),
                      const SizedBox(height: CityCareSpacing.xs),
                    ],
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: CityCareColors.danger,
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
        const SizedBox(height: CityCareSpacing.lg),
        if (a.hasQueue && a.tokenNumber != null) ...[
          Container(
            padding: const EdgeInsets.all(CityCareSpacing.lg),
            decoration: BoxDecoration(
              color: CityCareColors.primary,
              borderRadius: BorderRadius.circular(CityCareRadius.lg),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.confirmation_number_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: CityCareSpacing.md),
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
          const SizedBox(height: CityCareSpacing.lg),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CityCareSpacing.lg,
              vertical: CityCareSpacing.sm,
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
        const SizedBox(height: CityCareSpacing.md),
        _VisitActions(appointment: a),
        if (a.status == AppointmentStatus.completed) ...[
          const SizedBox(height: CityCareSpacing.lg),
          _VisitSummarySection(appointment: a),
        ],
        if (a.clinicSlug != null) ...[
          const SizedBox(height: CityCareSpacing.md),
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

/// Add to calendar · Directions · Call clinic. Phone and coordinates come
/// from the clinic's public profile (cached), when it has them.
class _VisitActions extends StatefulWidget {
  const _VisitActions({required this.appointment});

  final Appointment appointment;

  @override
  State<_VisitActions> createState() => _VisitActionsState();
}

class _VisitActionsState extends State<_VisitActions> {
  ClinicDetail? _clinic;

  @override
  void initState() {
    super.initState();
    final slug = widget.appointment.clinicSlug;
    if (slug != null) {
      context
          .read<ClinicRepository>()
          .detail(slug)
          .then((c) {
            if (mounted) setState(() => _clinic = c);
          })
          .catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appointment;
    final clinic = _clinic;
    final branch =
        clinic?.locations.where((l) => l.id == a.locationId).firstOrNull ??
        clinic?.locations.firstOrNull;
    final phone = branch?.phone ?? clinic?.publicPhone;
    final address = branch?.address ?? a.locationCity;
    final place = [
      a.clinicName,
      address,
    ].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    final upcoming =
        a.status.isActive && a.scheduledEnd.isAfter(DateTime.now().toUtc());

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (upcoming)
          ActionChip(
            avatar: const Icon(Icons.event_rounded, size: 18),
            label: const Text('Add to calendar'),
            onPressed: () => ExternalActions.addToCalendar(
              context,
              title: 'Doctor visit: ${a.doctorName ?? 'appointment'}',
              start: a.scheduledStart,
              end: a.scheduledEnd,
              details: [
                a.appointmentTypeName,
                if (a.isToken && a.tokenNumber != null)
                  'Token #${a.tokenNumber}',
                'Booked with CityCare',
              ].whereType<String>().join(', '),
              location: place.isEmpty ? null : place,
            ),
          ),
        if (place.isNotEmpty)
          ActionChip(
            avatar: const Icon(Icons.directions_rounded, size: 18),
            label: const Text('Directions'),
            onPressed: () => ExternalActions.directions(
              context,
              label: a.clinicName ?? 'Clinic',
              address: address,
              latitude: branch?.latitude,
              longitude: branch?.longitude,
            ),
          ),
        if (phone != null)
          ActionChip(
            avatar: const Icon(Icons.call_rounded, size: 18),
            label: const Text('Call clinic'),
            onPressed: () => ExternalActions.call(context, phone),
          ),
      ],
    );
  }
}

/// The doctor's signed summary and prescriptions for a completed visit.
class _VisitSummarySection extends StatefulWidget {
  const _VisitSummarySection({required this.appointment});

  final Appointment appointment;

  @override
  State<_VisitSummarySection> createState() => _VisitSummarySectionState();
}

class _VisitSummarySectionState extends State<_VisitSummarySection> {
  late final Future<VisitSummary?> _summary = context
      .read<RecordsRepository>()
      .visitSummary(
        organizationId: widget.appointment.organizationId,
        appointmentId: widget.appointment.id,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<VisitSummary?>(
      future: _summary,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const CityCareSkeletonCard(avatar: false, lines: 3);
        }
        final summary = snap.data;
        if (summary == null || summary.isEmpty) {
          return const SizedBox.shrink();
        }
        Widget field(String label, String? value) => value == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: CityCareSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(value, style: theme.textTheme.bodyLarge),
                  ],
                ),
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CityCareSectionHeader(title: 'Visit summary'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(CityCareSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    field('Diagnosis', summary.assessment),
                    field('Plan', summary.plan),
                    field('Instructions', summary.instructions),
                    field('Tests advised', summary.testsAdvised),
                    if (summary.followUpDate != null)
                      field(
                        'Follow-up',
                        ClinicTime.date(
                          summary.followUpDate!,
                          widget.appointment.timezone,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            for (final p in summary.prescriptions) ...[
              const SizedBox(height: CityCareSpacing.md),
              PrescriptionCard(prescription: p),
            ],
          ],
        );
      },
    );
  }
}
