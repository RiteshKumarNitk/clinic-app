import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/dependencies.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/citycare.dart';
import '../../appointments/presentation/booking_draft.dart';
import '../../appointments/presentation/booking_widgets.dart';
import '../../appointments/presentation/booking_for_picker.dart';
import '../../appointments/presentation/patient_details_form.dart';
import '../../doctors/data/doctor_repository.dart';
import '../data/queue_models.dart';
import '../data/queue_repository.dart';

/// Get Today's Token — re-reads the live window, then asks the server for a
/// token. A repeat tap returns the token the patient already holds.
class TokenConfirmScreen extends StatefulWidget {
  const TokenConfirmScreen({super.key, required this.draft});

  final BookingDraft draft;

  @override
  State<TokenConfirmScreen> createState() => _TokenConfirmScreenState();
}

class _TokenConfirmScreenState extends State<TokenConfirmScreen> {
  final _patient = GlobalKey<PatientDetailsFormState>();
  final _for = GlobalKey<BookingForPickerState>();
  bool _submitting = false;
  String? _error;

  Future<void> _book() async {
    final bookingFor = _for.currentState?.read();
    final patient = _patient.currentState?.read();
    if (patient == null || bookingFor == null) return;
    final d = widget.draft;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final token = await context.read<QueueRepository>().bookToken(
        TokenRequest(
          organizationId: d.organizationId,
          doctorId: d.doctor.id,
          locationId: d.location?.id,
          patient: patient,
          bookingFor: bookingFor,
        ),
      );
      if (!mounted) return;
      context.read<Dependencies>().appointmentsChanged.bump();
      if (token.reused) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You already have token #${token.tokenNumber} for today.',
            ),
          ),
        );
      }
      context.pushReplacement(
        '${Routes.queue(token.appointmentId)}?org=${d.organizationId}',
      );
    } catch (e) {
      developer.log(
        'Token booking failed: ${debugDescription(e)}',
        name: 'Booking',
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = friendlyMessage(
          e,
          fallback: "We couldn't get a token right now. Please try again.",
        );
        // Debug builds show the server's real reason under the message.
        if (kDebugMode) _error = '$_error\n\n${debugDescription(e)}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Today's token")),
      body: AsyncView<TokenWindow>(
        load: () => context.read<DoctorRepository>().tokenWindow(d.doctor.id),
        errorMessage: "We couldn't check today's tokens.",
        loading: const CityCareLoading(count: 2),
        builder: (context, window, reload) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(CityCareSpacing.gutter),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CityCareSpacing.lg,
                        vertical: CityCareSpacing.sm,
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
                          SummaryRow(
                            icon: Icons.schedule_rounded,
                            label: 'Queue starts',
                            value: window.queueStartAt,
                          ),
                          SummaryRow(
                            icon: Icons.timer_outlined,
                            label: 'Tokens',
                            value: '${window.opensAt} – ${window.closesAt}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: CityCareSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(CityCareSpacing.md),
                    decoration: BoxDecoration(
                      color: window.bookable
                          ? CityCareColors.successSoft
                          : CityCareColors.warningSoft,
                      borderRadius: BorderRadius.circular(CityCareRadius.md),
                    ),
                    child: Text(
                      window.bookable
                          ? 'Tokens are open now. Your number is assigned by '
                                'the clinic when you confirm.'
                          : window.reason ??
                                'Tokens are not available right now.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: window.bookable
                            ? CityCareColors.success
                            : CityCareColors.warning,
                      ),
                    ),
                  ),
                  if (window.bookable) ...[
                    const SizedBox(height: CityCareSpacing.xl),
                    BookingForPicker(
                      key: _for,
                      organizationId: d.organizationId,
                    ),
                    const SizedBox(height: CityCareSpacing.xl),
                    Text('Your details', style: theme.textTheme.titleMedium),
                    const SizedBox(height: CityCareSpacing.md),
                    PatientDetailsForm(key: _patient),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: CityCareSpacing.lg),
                    Text(
                      _error!,
                      style: const TextStyle(color: CityCareColors.danger),
                    ),
                  ],
                ],
              ),
            ),
            BottomAction(
              child: window.bookable
                  ? CityCareButton(
                      onPressed: _book,
                      busy: _submitting,
                      label: 'Get my token',
                      icon: Icons.confirmation_number_outlined,
                      accentRing: true,
                    )
                  : CityCareOutlinedButton(
                      onPressed: reload,
                      label: 'Check again',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
