import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/dependencies.dart';
import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/utils/clinic_time.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/sign_in_prompt_view.dart';
import '../data/appointment_models.dart';
import '../data/appointment_repository.dart';
import 'appointment_card.dart';

/// Splits appointments into Upcoming (active, today or later at the clinic)
/// and Past (everything else, newest first).
({List<Appointment> upcoming, List<Appointment> past}) splitAppointments(
  List<Appointment> all, {
  DateTime? now,
}) {
  final upcoming = <Appointment>[];
  final past = <Appointment>[];
  for (final a in all) {
    final today = ClinicTime.today(a.timezone, now: now);
    final local = ClinicTime.local(a.scheduledStart, a.timezone);
    final day = DateTime(local.year, local.month, local.day);
    final stillAhead = a.isToken
        ? !day.isBefore(today)
        : a.scheduledEnd.isAfter((now ?? DateTime.now()).toUtc());
    if (a.status.isActive && stillAhead) {
      upcoming.add(a);
    } else {
      past.add(a);
    }
  }
  upcoming.sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
  past.sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));
  return (upcoming: upcoming, past: past);
}

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<AppointmentRepository>();
    final version = context.watch<AppointmentsChanged>().version;
    if (!context.watch<AuthController>().isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('My appointments')),
        body: const SignInPromptView(
          icon: Icons.event_note_rounded,
          title: 'Your visits, in one place',
          message:
              'Sign in to see upcoming appointments, past visits and '
              'your queue tokens.',
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My appointments'),
          bottom: const TabBar(
            labelColor: CityCareColors.primaryDark,
            indicatorColor: CityCareColors.primary,
            unselectedLabelColor: CityCareColors.inkMuted,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: AsyncView<List<Appointment>>(
          key: ValueKey(version),
          load: repo.myAppointments,
          errorMessage: "We couldn't load your appointments.",
          builder: (context, all, reload) {
            final split = splitAppointments(all);
            return TabBarView(
              children: [
                _List(
                  items: split.upcoming,
                  onRefresh: reload,
                  empty: CityCareEmptyState(
                    icon: Icons.event_available_outlined,
                    title: "You don't have any upcoming appointments.",
                    message: 'Find a clinic and book a visit in a few taps.',
                    actionLabel: 'Find healthcare',
                    onAction: () => context.go(Routes.find),
                  ),
                ),
                _List(
                  items: split.past,
                  onRefresh: reload,
                  empty: const CityCareEmptyState(
                    icon: Icons.history_rounded,
                    title: 'No past appointments yet.',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    required this.items,
    required this.onRefresh,
    required this.empty,
  });

  final List<Appointment> items;
  final Future<void> Function() onRefresh;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [SizedBox(height: 480, child: empty)],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(CityCareSpacing.gutter),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: CityCareSpacing.md),
              itemBuilder: (_, i) => AppointmentCard(appointment: items[i]),
            ),
    );
  }
}
