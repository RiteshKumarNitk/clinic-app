import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/dependencies.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/clinic_time.dart';
import '../data/appointment_models.dart';
import '../data/appointment_repository.dart';
import 'booking_draft.dart';
import 'booking_widgets.dart';
import 'booking_for_picker.dart';
import 'patient_details_form.dart';

/// Step 3 — review and confirm. The server re-validates the slot inside a
/// transaction; a lost race comes back as a friendly "choose another time".
class ConfirmBookingScreen extends StatefulWidget {
  const ConfirmBookingScreen({super.key, required this.draft});

  final BookingDraft draft;

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  final _patient = GlobalKey<PatientDetailsFormState>();
  final _for = GlobalKey<BookingForPickerState>();
  final _reason = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _slotGone = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _book() async {
    final bookingFor = _for.currentState?.read();
    final patient = _patient.currentState?.read();
    if (patient == null || bookingFor == null) return;
    final draft = widget.draft;
    setState(() {
      _submitting = true;
      _error = null;
      _slotGone = false;
    });
    try {
      final appt = await context.read<AppointmentRepository>().book(
        BookingRequest(
          organizationId: draft.organizationId,
          doctorId: draft.doctor.id,
          scheduledStart: draft.slot!.start,
          appointmentTypeId: draft.type?.id,
          locationId: draft.location?.id,
          reason: _reason.text,
          patient: patient,
          bookingFor: bookingFor,
        ),
      );
      if (!mounted) return;
      context.read<Dependencies>().appointmentsChanged.bump();
      context.go(
        Routes.bookingConfirmed,
        extra: BookingResult(appointment: appt, draft: draft),
      );
    } catch (e) {
      developer.log('Booking failed: ${debugDescription(e)}', name: 'Booking');
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = friendlyMessage(
          e,
          fallback: "We couldn't book this appointment. Please try again.",
        );
        // Debug builds show the server's real reason under the message.
        if (kDebugMode) _error = '$_error\n\n${debugDescription(e)}';
        _slotGone = isSlotConflict(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final tz = d.timezone;
    final slot = d.slot!;
    final theme = Theme.of(context);
    final fee = formatFee(d.doctor.consultationFeeMinor);

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                BookingHeader(draft: d, step: 3, title: 'Confirm booking'),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClinicSpacing.gutter,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                  value:
                                      '${d.type!.name} · ${d.type!.durationMinutes} min',
                                ),
                              SummaryRow(
                                icon: Icons.event_outlined,
                                label: 'Date',
                                value: ClinicTime.date(slot.start, tz),
                              ),
                              SummaryRow(
                                icon: Icons.schedule_rounded,
                                label: 'Time',
                                value: ClinicTime.time(slot.start, tz),
                              ),
                              if (d.location != null)
                                SummaryRow(
                                  icon: Icons.place_outlined,
                                  label: 'Location',
                                  value: [
                                    d.location!.name,
                                    if (d.location!.address.isNotEmpty)
                                      d.location!.address,
                                  ].join('\n'),
                                ),
                              if (fee != null)
                                SummaryRow(
                                  icon: Icons.payments_outlined,
                                  label: 'Fee',
                                  value: '$fee · pay at clinic',
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: ClinicSpacing.xl),
                      BookingForPicker(
                        key: _for,
                        organizationId: d.organizationId,
                      ),
                      const SizedBox(height: ClinicSpacing.xl),
                      Text('Your details', style: theme.textTheme.titleMedium),
                      const SizedBox(height: ClinicSpacing.md),
                      PatientDetailsForm(key: _patient),
                      const SizedBox(height: ClinicSpacing.md),
                      TextField(
                        controller: _reason,
                        maxLines: 3,
                        minLines: 2,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Reason for visit (optional)',
                          alignLabelWithHint: true,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: ClinicSpacing.sm),
                        _ErrorBanner(
                          message: _error!,
                          actionLabel: _slotGone ? 'Choose another time' : null,
                          onAction: _slotGone ? () => context.pop() : null,
                        ),
                      ],
                      const SizedBox(height: ClinicSpacing.xl),
                    ],
                  ),
                ),
              ],
            ),
          ),
          BottomAction(
            child: FilledButton(
              onPressed: _submitting ? null : _book,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Confirm booking'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClinicSpacing.md),
      decoration: BoxDecoration(
        color: ClinicColors.dangerSoft,
        borderRadius: BorderRadius.circular(ClinicRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: ClinicColors.danger,
                size: 20,
              ),
              const SizedBox(width: ClinicSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: ClinicColors.danger),
                ),
              ),
            ],
          ),
          if (actionLabel != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ),
        ],
      ),
    );
  }
}
