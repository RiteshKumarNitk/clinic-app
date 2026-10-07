import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/clinic_time.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../appointments/presentation/booking_draft.dart';
import '../../queue/data/queue_models.dart';
import '../data/doctor_models.dart';
import '../data/doctor_repository.dart';

class DoctorDetailsScreen extends StatelessWidget {
  const DoctorDetailsScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<DoctorRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor')),
      body: AsyncView<DoctorDetail>(
        load: () => repo.detail(doctorId),
        errorMessage: "We couldn't load this doctor.",
        loading: const SkeletonList(count: 3, lines: 3),
        builder: (context, doctor, reload) => _DoctorBody(doctor: doctor),
      ),
    );
  }
}

class _DoctorBody extends StatefulWidget {
  const _DoctorBody({required this.doctor});

  final DoctorDetail doctor;

  @override
  State<_DoctorBody> createState() => _DoctorBodyState();
}

class _DoctorBodyState extends State<_DoctorBody> {
  Future<TokenWindow>? _window;

  @override
  void initState() {
    super.initState();
    if (widget.doctor.bookingMode.offersTokens) {
      _window = context.read<DoctorRepository>().tokenWindow(widget.doctor.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.doctor;
    final theme = Theme.of(context);
    final fee = formatFee(d.consultationFeeMinor);
    final location = d.clinic.locations.isEmpty
        ? null
        : d.clinic.locations
              .map((l) => [l.name, l.city].whereType<String>().join(', '))
              .join('\n');
    final draft = BookingDraft(doctor: d);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(ClinicSpacing.gutter),
            children: [
              Center(
                child: EntityAvatar(
                  label: d.displayName,
                  imageUrl: d.photoUrl,
                  size: 96,
                  circle: true,
                ),
              ),
              const SizedBox(height: ClinicSpacing.lg),
              Text(
                d.displayName,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              if (d.specialty != null) ...[
                const SizedBox(height: 4),
                Text(
                  d.specialty!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: ClinicColors.primaryDark,
                  ),
                ),
              ],
              if (d.qualifications != null) ...[
                const SizedBox(height: 4),
                Text(
                  d.qualifications!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: ClinicSpacing.xl),
              _Facts(
                facts: [
                  if (d.yearsOfExperience != null)
                    ('Experience', '${d.yearsOfExperience} yrs'),
                  if (fee != null) ('Consultation', fee),
                  if (d.consultationDurationMin != null)
                    ('Visit length', '${d.consultationDurationMin} min'),
                ],
              ),
              const SizedBox(height: ClinicSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(ClinicSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoRow(
                        icon: Icons.local_hospital_outlined,
                        text: d.clinic.ref.name,
                      ),
                      if (location != null)
                        InfoRow(icon: Icons.place_outlined, text: location),
                      if (d.languages.isNotEmpty)
                        InfoRow(
                          icon: Icons.translate_rounded,
                          text: d.languages.join(', '),
                        ),
                      InfoRow(
                        icon: Icons.event_note_outlined,
                        text: switch (d.bookingMode) {
                          BookingMode.scheduled => 'Appointments by time slot',
                          BookingMode.sameDayToken => 'Same-day tokens only',
                          BookingMode.both =>
                            'Time-slot appointments and same-day tokens',
                        },
                      ),
                    ],
                  ),
                ),
              ),
              if (d.bio != null) ...[
                const SizedBox(height: ClinicSpacing.lg),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(ClinicSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('About', style: theme.textTheme.titleSmall),
                        const SizedBox(height: ClinicSpacing.sm),
                        Text(d.bio!, style: theme.textTheme.bodyLarge),
                      ],
                    ),
                  ),
                ),
              ],
              if (_window != null) ...[
                const SizedBox(height: ClinicSpacing.lg),
                FutureBuilder<TokenWindow>(
                  future: _window,
                  builder: (_, snap) => snap.hasData
                      ? _TokenWindowCard(window: snap.data!)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
        _ActionBar(doctor: d, draft: draft, window: _window),
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.facts});

  final List<(String, String)> facts;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final (i, f) in facts.indexed) ...[
          if (i > 0) const SizedBox(width: ClinicSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: ClinicColors.surface,
                borderRadius: BorderRadius.circular(ClinicRadius.md),
                border: Border.all(color: ClinicColors.border),
              ),
              child: Column(
                children: [
                  Text(f.$2, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(f.$1, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TokenWindowCard extends StatelessWidget {
  const _TokenWindowCard({required this.window});

  final TokenWindow window;

  @override
  Widget build(BuildContext context) {
    final open = window.bookable;
    return Container(
      padding: const EdgeInsets.all(ClinicSpacing.lg),
      decoration: BoxDecoration(
        color: open ? ClinicColors.successSoft : ClinicColors.warningSoft,
        borderRadius: BorderRadius.circular(ClinicRadius.lg),
      ),
      child: Row(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            color: open ? ClinicColors.success : ClinicColors.warning,
          ),
          const SizedBox(width: ClinicSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  open ? "Today's tokens are open" : "Today's tokens",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  open
                      ? 'Book until ${window.closesAt}. Queue starts at ${window.queueStartAt}.'
                      : window.reason ??
                            'Tokens open ${window.opensAt}–${window.closesAt}.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.doctor,
    required this.draft,
    required this.window,
  });

  final DoctorDetail doctor;
  final BookingDraft draft;
  final Future<TokenWindow>? window;

  @override
  Widget build(BuildContext context) {
    final mode = doctor.bookingMode;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ClinicSpacing.gutter,
        ClinicSpacing.md,
        ClinicSpacing.gutter,
        ClinicSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: ClinicColors.surface,
        border: Border(top: BorderSide(color: ClinicColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mode.offersSlots)
              FilledButton.icon(
                onPressed: () =>
                    context.push(Routes.bookType(doctor.id), extra: draft),
                icon: const Icon(Icons.event_available_rounded),
                label: const Text('Book appointment'),
              ),
            if (mode.offersTokens) ...[
              if (mode.offersSlots) const SizedBox(height: ClinicSpacing.sm),
              FutureBuilder<TokenWindow>(
                future: window,
                builder: (context, snap) {
                  final bookable = snap.data?.bookable ?? false;
                  final child = Text(
                    snap.connectionState != ConnectionState.done
                        ? 'Checking today\'s tokens…'
                        : bookable
                        ? "Get today's token"
                        : "Today's tokens unavailable",
                  );
                  void go() =>
                      context.push(Routes.token(doctor.id), extra: draft);
                  return mode.offersSlots
                      ? OutlinedButton(
                          onPressed: bookable ? go : null,
                          child: child,
                        )
                      : FilledButton(
                          onPressed: bookable ? go : null,
                          child: child,
                        );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
