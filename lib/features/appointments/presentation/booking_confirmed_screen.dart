import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/clinic_time.dart';
import '../data/appointment_models.dart';
import 'booking_draft.dart';
import 'booking_widgets.dart';

/// Appointment Confirmed — built from the server's response (id, status,
/// time, timezone) plus the clinic/doctor context the patient booked in.
class BookingConfirmedScreen extends StatelessWidget {
  const BookingConfirmedScreen({super.key, required this.result});

  final BookingResult result;

  @override
  Widget build(BuildContext context) {
    final a = result.appointment;
    final d = result.draft;
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.appointments);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(ClinicSpacing.gutter),
                  children: [
                    const SizedBox(height: ClinicSpacing.xl),
                    Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.6, end: 1),
                        duration: const Duration(milliseconds: 450),
                        curve: Curves.easeOutBack,
                        builder: (_, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Container(
                          width: 88,
                          height: 88,
                          decoration: const BoxDecoration(
                            color: ClinicColors.successSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: ClinicColors.success,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: ClinicSpacing.lg),
                    Text(
                      'Appointment confirmed',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: ClinicSpacing.sm),
                    Text(
                      'We\'ve saved it to your appointments.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: ClinicSpacing.xl),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ClinicSpacing.lg,
                          vertical: ClinicSpacing.sm,
                        ),
                        child: Column(
                          children: [
                            SummaryRow(
                              icon: Icons.local_hospital_outlined,
                              label: 'Clinic',
                              value: d.clinicName,
                            ),
                            SummaryRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Doctor',
                              value: d.doctor.displayName,
                            ),
                            if (d.type != null)
                              SummaryRow(
                                icon: Icons.medical_information_outlined,
                                label: 'Visit',
                                value: d.type!.name,
                              ),
                            SummaryRow(
                              icon: Icons.event_outlined,
                              label: 'Date',
                              value: ClinicTime.date(
                                a.scheduledStart,
                                a.timezone,
                              ),
                            ),
                            SummaryRow(
                              icon: Icons.schedule_rounded,
                              label: 'Time',
                              value: ClinicTime.time(
                                a.scheduledStart,
                                a.timezone,
                              ),
                            ),
                            if (d.location != null)
                              SummaryRow(
                                icon: Icons.place_outlined,
                                label: 'Location',
                                value: d.location!.name,
                              ),
                            SummaryRow(
                              icon: Icons.info_outline_rounded,
                              label: 'Status',
                              value: a.status.label,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              BottomAction(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton(
                      onPressed: () {
                        context.go(Routes.appointments);
                        context.push(
                          Routes.appointment(a.organizationId, a.id),
                        );
                      },
                      child: const Text('View appointment'),
                    ),
                    const SizedBox(height: ClinicSpacing.sm),
                    TextButton(
                      onPressed: () => context.go(Routes.home),
                      child: const Text('Back to home'),
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
