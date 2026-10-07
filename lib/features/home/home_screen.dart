import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/dependencies.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/errors/api_exception.dart';
import '../../core/utils/clinic_time.dart';
import '../../core/widgets/state_views.dart';
import '../appointments/data/appointment_models.dart';
import '../appointments/data/appointment_repository.dart';
import '../appointments/presentation/appointment_card.dart';
import '../appointments/presentation/appointments_screen.dart';
import '../clinics/data/clinic_models.dart';
import '../clinics/data/clinic_repository.dart';
import '../clinics/presentation/clinic_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Paged<ClinicSummary>> _clinics;
  late Future<List<Appointment>> _appointments;
  int _seenVersion = -1;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  void _loadClinics() {
    _clinics = context.read<ClinicRepository>().list(pageSize: 5);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadClinics();
      _appointments = context.read<AppointmentRepository>().myAppointments();
    });
    await Future.wait([
      _clinics.then((_) {}, onError: (_) {}),
      _appointments.then((_) {}, onError: (_) {}),
    ]);
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final theme = Theme.of(context);
    // Reload appointments after any booking or cancellation elsewhere.
    final version = context.watch<AppointmentsChanged>().version;
    if (version != _seenVersion) {
      _seenVersion = version;
      _appointments = context.read<AppointmentRepository>().myAppointments();
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              ClinicSpacing.gutter,
              ClinicSpacing.lg,
              ClinicSpacing.gutter,
              ClinicSpacing.xxl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user == null
                              ? _greeting()
                              : '${_greeting()}, ${user.firstName}',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Find and book healthcare.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go(Routes.profile),
                    child: EntityAvatar(
                      label: user?.fullName ?? '?',
                      imageUrl: user?.avatarUrl,
                      size: 44,
                      circle: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ClinicSpacing.lg),
              TextField(
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search doctors, clinics, specialties',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onSubmitted: (q) => context.go(
                  q.trim().isEmpty ? Routes.find : Routes.findWithQuery(q),
                ),
              ),
              const SizedBox(height: ClinicSpacing.xl),
              FutureBuilder<List<Appointment>>(
                future: _appointments,
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  final upcoming = splitAppointments(snap.data!).upcoming;
                  if (upcoming.isEmpty) return const SizedBox.shrink();
                  final activeQueue = upcoming
                      .where(
                        (a) =>
                            a.hasQueue &&
                            ClinicTime.today(a.timezone) ==
                                _day(a.scheduledStart, a.timezone),
                      )
                      .firstOrNull;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (activeQueue != null) ...[
                        _ActiveQueueCard(appointment: activeQueue),
                        const SizedBox(height: ClinicSpacing.xl),
                      ],
                      SectionHeader(
                        title: 'Upcoming appointment',
                        actionLabel: upcoming.length > 1 ? 'See all' : null,
                        onAction: () => context.go(Routes.appointments),
                      ),
                      AppointmentCard(appointment: upcoming.first),
                      const SizedBox(height: ClinicSpacing.xl),
                    ],
                  );
                },
              ),
              SectionHeader(
                title: 'Find healthcare',
                actionLabel: 'View all',
                onAction: () => context.go(Routes.find),
              ),
              FutureBuilder<Paged<ClinicSummary>>(
                future: _clinics,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Column(
                      children: [
                        SkeletonCard(),
                        SizedBox(height: ClinicSpacing.md),
                        SkeletonCard(),
                      ],
                    );
                  }
                  if (snap.hasError) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(ClinicSpacing.lg),
                        child: Column(
                          children: [
                            Text(
                              friendlyMessage(
                                snap.error!,
                                fallback: "We couldn't load clinics.",
                              ),
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: () => setState(_loadClinics),
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final page = snap.data!;
                  if (page.items.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(ClinicSpacing.lg),
                        child: Text('No clinics are available right now.'),
                      ),
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final c in page.items) ...[
                        ClinicCard(clinic: c, compact: true),
                        const SizedBox(height: ClinicSpacing.md),
                      ],
                      OutlinedButton(
                        onPressed: () => context.go(Routes.find),
                        child: Text(
                          page.total > page.items.length
                              ? 'View all ${page.total} clinics'
                              : 'View all clinics',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static DateTime _day(DateTime instant, String tz) {
    final l = ClinicTime.local(instant, tz);
    return DateTime(l.year, l.month, l.day);
  }
}

class _ActiveQueueCard extends StatelessWidget {
  const _ActiveQueueCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Material(
      color: ClinicColors.primary,
      borderRadius: BorderRadius.circular(ClinicRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(ClinicRadius.lg),
        onTap: () =>
            context.push('${Routes.queue(a.id)}?org=${a.organizationId}'),
        child: Padding(
          padding: const EdgeInsets.all(ClinicSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(ClinicRadius.md),
                ),
                child: Text(
                  a.tokenNumber == null ? '…' : '#${a.tokenNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: ClinicSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active queue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        a.doctorName,
                        a.clinicName,
                      ].whereType<String>().join(' · '),
                      style: const TextStyle(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Text(
                'Track',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
