import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/dependencies.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/utils/clinic_time.dart';
import '../../../core/widgets/state_views.dart';
import '../data/appointment_models.dart';
import '../data/appointment_repository.dart';
import 'booking_draft.dart';
import 'booking_widgets.dart';

/// Step 2 — date, then the server's available slots for that date.
class SlotPickerScreen extends StatefulWidget {
  const SlotPickerScreen({super.key, required this.draft});

  final BookingDraft draft;

  @override
  State<SlotPickerScreen> createState() => _SlotPickerScreenState();
}

class _SlotPickerScreenState extends State<SlotPickerScreen> {
  static const _daysAhead = 21;

  late final DateTime _today = ClinicTime.today(widget.draft.timezone);
  late DateTime _day = _today;
  Slot? _slot;
  Future<SlotDay>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _slot = null;
      _future = context.read<AppointmentRepository>().slots(
        doctorId: widget.draft.doctor.id,
        day: _day,
        appointmentTypeId: widget.draft.type?.id,
      );
    });
  }

  bool _saving = false;

  /// Reschedule: confirm, then move the appointment on the server.
  Future<void> _reschedule(SlotDay day) async {
    final old = widget.draft.rescheduleOf!;
    final slot = _slot!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change appointment time?'),
        content: Text(
          'From ${ClinicTime.date(old.scheduledStart, old.timezone)}, '
          '${ClinicTime.time(old.scheduledStart, old.timezone)}\n'
          'To ${ClinicTime.date(slot.start, day.timezone)}, '
          '${ClinicTime.time(slot.start, day.timezone)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep current'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Change'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final changed = context.read<Dependencies>().appointmentsChanged;
    try {
      final fresh = await context.read<AppointmentRepository>().reschedule(
        organizationId: old.organizationId,
        appointmentId: old.id,
        scheduledStart: slot.start,
        appointmentTypeId: widget.draft.type?.id ?? old.appointmentTypeId,
      );
      changed.bump();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Appointment time changed.')),
      );
      // Replace the old appointment page with the new one.
      context.pop();
      context.pushReplacement(
        Routes.appointment(fresh.organizationId, fresh.id),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            friendlyMessage(
              e,
              fallback: "We couldn't change the time. Please try again.",
            ),
          ),
        ),
      );
      if (isSlotConflict(e)) _load();
    }
  }

  void _continue(SlotDay day) {
    if (widget.draft.isReschedule) {
      _reschedule(day);
      return;
    }
    context.push(
      Routes.bookConfirm(widget.draft.doctor.id),
      extra: widget.draft.copyWith(slot: _slot, timezone: day.timezone),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder<SlotDay>(
        future: _future,
        builder: (context, snap) {
          final day = snap.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookingHeader(
                draft: widget.draft,
                step: widget.draft.isReschedule ? 0 : 2,
                title: widget.draft.isReschedule
                    ? 'Choose a new time'
                    : 'Pick a date & time',
              ),
              _DateStrip(
                start: _today,
                count: _daysAhead,
                selected: _day,
                onSelected: (d) {
                  _day = d;
                  _load();
                },
              ),
              const SizedBox(height: ClinicSpacing.md),
              const Divider(),
              Expanded(child: _slots(snap)),
              BottomAction(
                child: FilledButton(
                  onPressed: _slot != null && day != null && !_saving
                      ? () => _continue(day)
                      : null,
                  child: Text(
                    _slot == null || day == null
                        ? 'Select a time'
                        : 'Continue · ${ClinicTime.time(_slot!.start, day.timezone)}',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _slots(AsyncSnapshot<SlotDay> snap) {
    if (snap.connectionState != ConnectionState.done) {
      return const _SlotSkeleton();
    }
    if (snap.hasError) {
      return ErrorView(
        message: friendlyMessage(
          snap.error!,
          fallback: "We couldn't load available times.",
        ),
        onRetry: _load,
      );
    }
    final day = snap.data!;
    if (day.slots.isEmpty) {
      final leadHours = (day.bookingLeadTimeMinutes / 60).ceil();
      return MessageView(
        icon: Icons.event_busy_outlined,
        title: 'No appointments are available for this date.',
        message: day.slotsHiddenByLeadTime > 0
            ? 'This clinic needs at least $leadHours '
                  '${leadHours == 1 ? 'hour' : 'hours'} notice. Try a later date.'
            : 'Please choose another date.',
        actionLabel: 'Next day',
        onAction: () {
          final next = _day.add(const Duration(days: 1));
          if (next.difference(_today).inDays < _daysAhead) {
            _day = next;
            _load();
          }
        },
      );
    }

    final groups = <String, List<Slot>>{};
    for (final s in day.slots) {
      final hour = ClinicTime.local(s.start, day.timezone).hour;
      final label = hour < 12
          ? 'Morning'
          : hour < 17
          ? 'Afternoon'
          : 'Evening';
      groups.putIfAbsent(label, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.all(ClinicSpacing.gutter),
      children: [
        for (final entry in groups.entries) ...[
          Text(entry.key, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: ClinicSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in entry.value)
                ChoiceChip(
                  label: Text(ClinicTime.time(s.start, day.timezone)),
                  selected: _slot?.start == s.start,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _slot?.start == s.start
                        ? ClinicColors.primaryDark
                        : ClinicColors.ink,
                  ),
                  side: BorderSide(
                    color: _slot?.start == s.start
                        ? ClinicColors.primary
                        : ClinicColors.border,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  onSelected: (_) => setState(() => _slot = s),
                ),
            ],
          ),
          const SizedBox(height: ClinicSpacing.lg),
        ],
        Text(
          'Times shown in the clinic\'s local time · ${day.durationMinutes} min visit',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.start,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final DateTime start;
  final int count;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: ClinicSpacing.gutter),
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = DateTime(start.year, start.month, start.day + i);
          final isSelected = d == selected;
          return Semantics(
            selected: isSelected,
            button: true,
            label: DateFormat('EEEE d MMMM').format(d),
            child: InkWell(
              borderRadius: BorderRadius.circular(ClinicRadius.md),
              onTap: () => onSelected(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 58,
                decoration: BoxDecoration(
                  color: isSelected
                      ? ClinicColors.primary
                      : ClinicColors.surface,
                  borderRadius: BorderRadius.circular(ClinicRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? ClinicColors.primary
                        : ClinicColors.border,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        i == 0 ? 'Today' : DateFormat('EEE').format(d),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white70
                              : ClinicColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : ClinicColors.ink,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(d),
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white70
                              : ClinicColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SlotSkeleton extends StatelessWidget {
  const _SlotSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(ClinicSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Skeleton(width: 80, height: 16),
          const SizedBox(height: ClinicSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              9,
              (_) => const Skeleton(width: 92, height: 44, radius: 10),
            ),
          ),
        ],
      ),
    );
  }
}
