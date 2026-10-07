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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CityCareSpacing.gutter,
        0,
        CityCareSpacing.gutter,
        CityCareSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step > 0) ...[
            BookingProgress(step: step),
            const SizedBox(height: CityCareSpacing.lg),
          ],
          Text(title, style: theme.textTheme.headlineMedium),
          const SizedBox(height: CityCareSpacing.md),
          Row(
            children: [
              CityCareAvatar(
                label: draft.doctor.displayName,
                imageUrl: draft.doctor.photoUrl,
                size: 40,
                circle: true,
              ),
              const SizedBox(width: CityCareSpacing.md),
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
        CityCareSpacing.gutter,
        CityCareSpacing.md,
        CityCareSpacing.gutter,
        CityCareSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: CityCareColors.surface,
        border: Border(top: BorderSide(color: CityCareColors.border)),
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
          Icon(icon, size: 20, color: CityCareColors.primary),
          const SizedBox(width: CityCareSpacing.md),
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

/// Appointment → Date → Time → Confirm, with the current step labelled.
class BookingProgress extends StatelessWidget {
  const BookingProgress({super.key, required this.step});

  /// 1-based: 1 type, 2 date, 3 time, 4 confirm.
  final int step;

  static const labels = ['Appointment', 'Date', 'Time', 'Confirm'];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step $step of ${labels.length}: ${labels[step - 1]}',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 1; i <= labels.length; i++) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: i <= step ? CityCareGradients.button : null,
                      color: i <= step ? null : CityCareColors.border,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (i == step) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: CityCareColors.lime,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x4012324A),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Flexible(
                        child: Text(
                          labels[i - 1],
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: i == step
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: i <= step
                                ? CityCareColors.primaryDark
                                : CityCareColors.inkFaint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (i < labels.length) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}
