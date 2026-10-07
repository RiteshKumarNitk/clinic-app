import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../auth/sign_in_sheet.dart';
import '../clinics/data/clinic_models.dart';
import '../clinics/data/clinic_repository.dart';
import '../clinics/presentation/clinic_card.dart';
import '../notifications/data/notifications_repository.dart';

/// The dashboard: search, quick actions, the patient's next visit and live
/// queue (when signed in), and clinics to explore.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Paged<ClinicSummary>> _clinics;
  Future<List<Appointment>> _appointments = Future.value(const []);
  String? _seenKey;

  @override
  void initState() {
    super.initState();
    _loadClinics();
  }

  void _loadClinics({bool refresh = false}) {
    _clinics = context.read<ClinicRepository>().list(
      pageSize: 5,
      refresh: refresh,
    );
  }

  /// Appointments exist only for a signed-in patient; guests get none.
  Future<List<Appointment>> _loadAppointments() =>
      context.read<AuthController>().isAuthenticated
      ? context.read<AppointmentRepository>().myAppointments()
      : Future.value(const []);

  Future<void> _refresh() async {
    setState(() {
      _loadClinics(refresh: true);
      _appointments = _loadAppointments();
    });
    await Future.wait([
      _clinics.then((_) {}, onError: (_) {}),
      _appointments.then((_) {}, onError: (_) {}),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    // Reload appointments after a booking/cancellation, or on sign-in.
    final key =
        '${context.watch<AppointmentsChanged>().version}:${auth.status.name}';
    if (key != _seenKey) {
      _seenKey = key;
      _appointments = _loadAppointments();
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(auth: auth),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClinicSpacing.gutter,
                  ClinicSpacing.xl,
                  ClinicSpacing.gutter,
                  ClinicSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (auth.isGuest) ...[
                      const _GuestBanner(),
                      const SizedBox(height: ClinicSpacing.xl),
                    ],
                    const _QuickActions(),
                    const SizedBox(height: ClinicSpacing.xl),
                    _MyVisits(future: _appointments),
                    SectionHeader(
                      title: 'Clinics to explore',
                      actionLabel: 'View all',
                      onAction: () => context.go(Routes.find),
                    ),
                    _Clinics(
                      future: _clinics,
                      onRetry: () => setState(_loadClinics),
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

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

class _Header extends StatelessWidget {
  const _Header({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    return Container(
      decoration: const BoxDecoration(
        gradient: ClinicGradients.hero,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ClinicSpacing.gutter,
            ClinicSpacing.lg,
            ClinicSpacing.gutter,
            ClinicSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user == null
                              ? '${_greeting()} 👋'
                              : '${_greeting()}, ${user.firstName} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'How can we help you today?',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  if (auth.isAuthenticated) const _Bell(),
                  const SizedBox(width: ClinicSpacing.sm),
                  GestureDetector(
                    onTap: () => context.go(Routes.profile),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: auth.isGuest
                          ? const CircleAvatar(
                              radius: 21,
                              backgroundColor: ClinicColors.primarySoft,
                              child: Icon(
                                Icons.person_outline_rounded,
                                color: ClinicColors.primary,
                              ),
                            )
                          : EntityAvatar(
                              label: user?.fullName ?? '?',
                              imageUrl: user?.avatarUrl,
                              size: 42,
                              circle: true,
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ClinicSpacing.lg),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ClinicRadius.md),
                  boxShadow: ClinicShadows.soft,
                ),
                child: TextField(
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search doctors, clinics, specialties',
                    prefixIcon: const Icon(Icons.search_rounded),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(ClinicRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (q) => context.go(
                    q.trim().isEmpty ? Routes.find : Routes.findWithQuery(q),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(ClinicSpacing.lg),
      decoration: BoxDecoration(
        color: ClinicColors.accentSoft,
        borderRadius: BorderRadius.circular(ClinicRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ClinicColors.surface,
              borderRadius: BorderRadius.circular(ClinicRadius.sm + 2),
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: ClinicColors.accent,
            ),
          ),
          const SizedBox(width: ClinicSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're browsing as a guest",
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  'Sign in to book visits and track your queue.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => requireSignIn(
              context,
              title: 'Sign in to Clinic',
              message:
                  'Book appointments, get same-day tokens and follow '
                  'your place in the queue.',
            ),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  Future<void> _appointments(BuildContext context) async {
    final ok = await requireSignIn(
      context,
      title: 'Sign in to see your visits',
      message:
          'Your appointments and tokens are linked to your Google account.',
    );
    if (ok && context.mounted) context.go(Routes.appointments);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            icon: Icons.local_hospital_rounded,
            label: 'Clinics',
            color: ClinicColors.primary,
            background: ClinicColors.primarySoft,
            onTap: () => context.go(Routes.find),
          ),
        ),
        const SizedBox(width: ClinicSpacing.md),
        Expanded(
          child: _ActionTile(
            icon: Icons.medical_services_rounded,
            label: 'Doctors',
            color: ClinicColors.accent,
            background: ClinicColors.accentSoft,
            onTap: () => context.go(Routes.findDoctors),
          ),
        ),
        const SizedBox(width: ClinicSpacing.md),
        Expanded(
          child: _ActionTile(
            icon: Icons.event_note_rounded,
            label: 'My visits',
            color: ClinicColors.warning,
            background: ClinicColors.warningSoft,
            onTap: () => _appointments(context),
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ClinicColors.surface,
      borderRadius: BorderRadius.circular(ClinicRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(ClinicRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: ClinicSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(ClinicRadius.lg),
            border: Border.all(color: ClinicColors.border),
          ),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(ClinicRadius.md),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: ClinicSpacing.sm),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Active queue + next appointment, only when there is something to show.
class _MyVisits extends StatelessWidget {
  const _MyVisits({required this.future});

  final Future<List<Appointment>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Appointment>>(
      future: future,
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final upcoming = splitAppointments(snap.data!).upcoming;
        if (upcoming.isEmpty) return const SizedBox.shrink();
        final activeQueue = upcoming.where((a) {
          if (!a.hasQueue) return false;
          final l = ClinicTime.local(a.scheduledStart, a.timezone);
          return ClinicTime.today(a.timezone) ==
              DateTime(l.year, l.month, l.day);
        }).firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (activeQueue != null) ...[
              _ActiveQueueCard(appointment: activeQueue),
              const SizedBox(height: ClinicSpacing.xl),
            ],
            SectionHeader(
              title: 'Upcoming visit',
              actionLabel: upcoming.length > 1 ? 'See all' : null,
              onAction: () => context.go(Routes.appointments),
            ),
            AppointmentCard(appointment: upcoming.first),
            const SizedBox(height: ClinicSpacing.xl),
          ],
        );
      },
    );
  }
}

class _Clinics extends StatelessWidget {
  const _Clinics({required this.future, required this.onRetry});

  final Future<Paged<ClinicSummary>> future;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Paged<ClinicSummary>>(
      future: future,
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
                    onPressed: onRetry,
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
    );
  }
}

class _ActiveQueueCard extends StatelessWidget {
  const _ActiveQueueCard({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    return Container(
      decoration: BoxDecoration(
        gradient: ClinicGradients.hero,
        borderRadius: BorderRadius.circular(ClinicRadius.lg),
        boxShadow: ClinicShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ClinicRadius.lg),
          onTap: () =>
              context.push('${Routes.queue(a.id)}?org=${a.organizationId}'),
          child: Padding(
            padding: const EdgeInsets.all(ClinicSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Track',
                    style: TextStyle(
                      color: ClinicColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Notification bell with the unread count across the patient's clinics.
class _Bell extends StatefulWidget {
  const _Bell();

  @override
  State<_Bell> createState() => _BellState();
}

class _BellState extends State<_Bell> {
  int _unread = 0;
  int? _seenVersion;

  void _refresh() {
    context
        .read<NotificationsRepository>()
        .inbox()
        .then((inbox) {
          if (mounted) setState(() => _unread = inbox.unreadCount);
        })
        .catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final version = context.watch<AppointmentsChanged>().version;
    if (version != _seenVersion) {
      _seenVersion = version;
      _refresh();
    }
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () async {
        await context.push(Routes.notifications);
        if (mounted) setState(() => _unread = 0);
      },
      icon: Badge(
        isLabelVisible: _unread > 0,
        label: Text(_unread > 9 ? '9+' : '$_unread'),
        backgroundColor: ClinicColors.danger,
        child: const Icon(
          Icons.notifications_none_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
