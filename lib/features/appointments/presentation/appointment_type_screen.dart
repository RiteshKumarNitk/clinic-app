import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../clinics/data/clinic_models.dart';
import 'booking_draft.dart';
import 'booking_widgets.dart';

/// Step 1 — the clinic's own appointment types, from the backend.
class AppointmentTypeScreen extends StatefulWidget {
  const AppointmentTypeScreen({super.key, required this.draft});

  final BookingDraft draft;

  @override
  State<AppointmentTypeScreen> createState() => _AppointmentTypeScreenState();
}

class _AppointmentTypeScreenState extends State<AppointmentTypeScreen> {
  late final List<AppointmentType> _types =
      widget.draft.doctor.clinic.appointmentTypes;
  late AppointmentType? _selected =
      widget.draft.type ?? (_types.length == 1 ? _types.first : null);

  void _continue() {
    context.push(
      Routes.bookTime(widget.draft.doctor.id),
      extra: widget.draft.copyWith(type: _selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A clinic with no configured types still books with its default length.
    final noTypes = _types.isEmpty;

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookingHeader(draft: widget.draft, step: 1, title: 'Type of visit'),
          Expanded(
            child: noTypes
                ? const MessageView(
                    icon: Icons.medical_information_outlined,
                    title: 'Standard consultation',
                    message:
                        'This clinic uses one visit type. Continue to pick a time.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClinicSpacing.gutter,
                    ),
                    itemCount: _types.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: ClinicSpacing.md),
                    itemBuilder: (context, i) {
                      final t = _types[i];
                      final selected = _selected?.id == t.id;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: selected
                              ? ClinicColors.primarySoft
                              : ClinicColors.surface,
                          borderRadius: BorderRadius.circular(ClinicRadius.lg),
                          border: Border.all(
                            color: selected
                                ? ClinicColors.primary
                                : ClinicColors.border,
                            width: selected ? 1.6 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(ClinicRadius.lg),
                          onTap: () => setState(() => _selected = t),
                          child: Padding(
                            padding: const EdgeInsets.all(ClinicSpacing.lg),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: selected
                                      ? ClinicColors.primary
                                      : ClinicColors.inkFaint,
                                ),
                                const SizedBox(width: ClinicSpacing.md),
                                Expanded(
                                  child: Text(
                                    t.name,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  '${t.durationMinutes} min',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          BottomAction(
            child: FilledButton(
              onPressed: noTypes || _selected != null ? _continue : null,
              child: const Text('Choose a time'),
            ),
          ),
        ],
      ),
    );
  }
}
