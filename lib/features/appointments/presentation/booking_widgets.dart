import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/state_views.dart';
import 'booking_draft.dart';

/// "Step 2 of 3" + a compact doctor/clinic header shared by booking steps.
class BookingHeader extends StatelessWidget {
  const BookingHeader({
    super.key,
    required this.draft,
    required this.step,
    required this.title,
  });

  final BookingDraft draft;
  final int step;
  final String title;

  static const steps = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClinicSpacing.gutter,
        0,
        ClinicSpacing.gutter,
        ClinicSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step > 0)
            Row(
              children: [
                for (var i = 1; i <= steps; i++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i <= step
                            ? ClinicColors.primary
                            : ClinicColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  if (i < steps) const SizedBox(width: 6),
                ],
              ],
            ),
          if (step > 0) const SizedBox(height: ClinicSpacing.md),
          if (step > 0)
            Text(
              'Step $step of $steps',
              style: theme.textTheme.labelMedium?.copyWith(
                color: ClinicColors.inkMuted,
              ),
            ),
          const SizedBox(height: 4),
          Text(title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: ClinicSpacing.md),
          Row(
            children: [
              EntityAvatar(
                label: draft.doctor.displayName,
                imageUrl: draft.doctor.photoUrl,
                size: 40,
                circle: true,
              ),
              const SizedBox(width: ClinicSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.doctor.displayName,
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      [
                        draft.doctor.specialty,
                        draft.clinicName,
                      ].whereType<String>().join(' · '),
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fixed bottom CTA area.
class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
      child: SafeArea(top: false, child: child),
    );
  }
}

/// Label/value line for summaries.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: ClinicColors.primary),
          const SizedBox(width: ClinicSpacing.md),
          SizedBox(
            width: 92,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(child: Text(value, style: theme.textTheme.titleSmall)),
        ],
      ),
    );
  }
}
