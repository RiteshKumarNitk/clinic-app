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
import '../../core/widgets/citycare.dart';
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

/// The dashboard: search, quick actions, the patient's live queue and next
/// visit (when signed in), and clinics to explore.
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
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: CityCareBackground(
          child: SafeArea(
            bottom: false,
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  CityCareSpacing.gutter,
                  CityCareSpacing.md,
                  CityCareSpacing.gutter,
                  CityCareSpacing.xxl,
                ),
                children: [
                  _TopBar(auth: auth),
                  const SizedBox(height: CityCareSpacing.xl),
                  _Greeting(auth: auth),
                  const SizedBox(height: CityCareSpacing.lg),
                  CityCareSearchBar(
                    hint: 'Search clinics or doctors',
                    onSubmitted: (q) => context.go(
                      q.trim().isEmpty ? Routes.find : Routes.findWithQuery(q),
                    ),
                  ),
                  const SizedBox(height: CityCareSpacing.xl),
                  FutureBuilder<List<Appointment>>(
                    future: _appointments,
                    builder: (context, snap) {
                      final upcoming = snap.hasData
                          ? splitAppointments(snap.data!).upcoming
                          : const <Appointment>[];
                      final activeQueue = upcoming.where((a) {
                        if (!a.hasQueue) return false;
                        final l = ClinicTime.local(
                          a.scheduledStart,
                          a.timezone,
                        );
                        return ClinicTime.today(a.timezone) ==
                            DateTime(l.year, l.month, l.day);
                      }).firstOrNull;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _QuickActions(activeQueue: activeQueue),
                          if (auth.isGuest) ...[
                            const SizedBox(height: CityCareSpacing.xl),
                            const _GuestBanner(),
                          ],
                          if (activeQueue != null) ...[
                            const SizedBox(height: CityCareSpacing.xl),
                            FadeSlideIn(
                              child: _ActiveQueueCard(appointment: activeQueue),
                            ),
                          ],
                          if (upcoming.isNotEmpty) ...[
                            const SizedBox(height: CityCareSpacing.xl),
                            CityCareSectionHeader(
                              title: 'Upcoming visit',
                              actionLabel: upcoming.length > 1
                                  ? 'See all'
                                  : null,
                              onAction: () => context.go(Routes.appointments),
                            ),
                            FadeSlideIn(
                              child: AppointmentCard(
                                appointment: upcoming.first,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: CityCareSpacing.xl),
                  CityCareSectionHeader(
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
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final user = auth.user;
    return Row(
      children: [
        const CityCareWordmark(size: 32),
        const Spacer(),
        if (auth.isAuthenticated) const _Bell(),
        const SizedBox(width: CityCareSpacing.xs),
        Semantics(
          button: true,
          label: 'Profile',
          child: GestureDetector(
            onTap: () => context.go(Routes.profile),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: CityCareColors.lime, width: 2),
              ),
              child: auth.isGuest || user == null
                  ? const CircleAvatar(
                      radius: 19,
                      backgroundColor: CityCareColors.primarySoft,
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: CityCareColors.primary,
                      ),
                    )
                  : CityCareAvatar(
                      label: user.fullName,
                      imageUrl: user.avatarUrl,
                      size: 38,
                      circle: true,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = auth.user?.firstName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Hi $name 👋',
              style: theme.textTheme.titleMedium?.copyWith(
                color: CityCareColors.primary,
              ),
            ),
          ),
        Text(
          'Find the right\nhealthcare for your city.',
          style: theme.textTheme.displaySmall?.copyWith(fontSize: 30),
        ),
        const SizedBox(height: CityCareSpacing.sm),
        Text(
          'Discover trusted clinics, doctors, appointments and live queues, '
          'all in one place.',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(CityCareSpacing.lg),
      decoration: BoxDecoration(
        gradient: CityCareGradients.accent,
        borderRadius: BorderRadius.circular(CityCareRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(CityCareRadius.sm),
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: CityCareColors.navy,
            ),
          ),
          const SizedBox(width: CityCareSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're browsing as a guest",
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: CityCareColors.navy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Sign in to book visits and track your queue.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: CityCareColors.navy,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: CityCareColors.navy,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            onPressed: () => requireSignIn(
              context,
              title: 'Sign in to CityCare',
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
  const _QuickActions({required this.activeQueue});

  final Appointment? activeQueue;

  Future<bool> _signedIn(BuildContext context, String title) => requireSignIn(
    context,
    title: title,
    message: 'Your appointments and tokens are linked to your Google account.',
  );

  Future<void> _appointments(BuildContext context) async {
    if (await _signedIn(context, 'Sign in to see your visits') &&
        context.mounted) {
      context.go(Routes.appointments);
    }
  }

  Future<void> _liveQueue(BuildContext context) async {
    if (!await _signedIn(context, 'Sign in to track your queue') ||
        !context.mounted) {
      return;
    }
    final a = activeQueue;
    if (a != null) {
      context.push('${Routes.queue(a.id)}?org=${a.organizationId}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "You don't have a token today. Get one from a doctor's page.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiles = [
      (
        Icons.local_hospital_rounded,
        'Clinics',
        CityCareColors.primary,
        CityCareColors.primarySoft,
        () => context.go(Routes.find),
      ),
      (
        Icons.medical_services_rounded,
        'Doctors',
        CityCareColors.accent,
        CityCareColors.accentSoft,
        () => context.go(Routes.findDoctors),
      ),
      (
        Icons.event_note_rounded,
        'Appointments',
        CityCareColors.primaryDark,
        const Color(0xFFEAF0FB),
        () => _appointments(context),
      ),
      (
        Icons.confirmation_number_rounded,
        'Live Queue',
        CityCareColors.navy,
        const Color(0xFFF2FBD0),
        () => _liveQueue(context),
      ),
    ];
    return Row(
      children: [
        for (final (i, t) in tiles.indexed) ...[
          if (i > 0) const SizedBox(width: CityCareSpacing.sm),
          Expanded(
            child: FadeSlideIn(
              index: i,
              child: _ActionTile(
                icon: t.$1,
                label: t.$2,
                color: t.$3,
                background: t.$4,
                onTap: t.$5,
                live: i == 3 && activeQueue != null,
              ),
            ),
          ),
        ],
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
    this.live = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;
  final bool live;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: CityCareColors.surface,
        borderRadius: BorderRadius.circular(CityCareRadius.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(CityCareRadius.lg),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: CityCareSpacing.md + 2,
              horizontal: 4,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(CityCareRadius.lg),
              border: Border.all(color: CityCareColors.border),
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(CityCareRadius.md),
                      ),
                      child: Icon(icon, color: color, size: 23),
                    ),
                    if (live)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: CityCareColors.lime,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: CityCareSpacing.sm),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: CityCareColors.ink,
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
              Skeleton(height: 190, radius: CityCareRadius.xl),
              SizedBox(height: CityCareSpacing.md),
              CityCareSkeletonCard(),
            ],
          );
        }
        if (snap.hasError) {
          return CityCareCard(
            child: Column(
              children: [
                Text(
                  friendlyMessage(
                    snap.error!,
                    fallback: "We couldn't load clinics.",
                  ),
                  textAlign: TextAlign.center,
                ),
                TextButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ),
          );
        }
        final page = snap.data!;
        if (page.items.isEmpty) {
          return const CityCareCard(
            child: Text('No clinics are available right now.'),
          );
        }
        final featured = page.items.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideIn(child: FeaturedClinicCard(clinic: featured)),
            for (final (i, c) in page.items.skip(1).indexed) ...[
              const SizedBox(height: CityCareSpacing.md),
              FadeSlideIn(
                index: i + 1,
                child: ClinicCard(clinic: c, compact: true),
              ),
            ],
            const SizedBox(height: CityCareSpacing.lg),
            CityCareOutlinedButton(
              onPressed: () => context.go(Routes.find),
              label: page.total > page.items.length
                  ? 'View all ${page.total} clinics'
                  : 'View all clinics',
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
        color: CityCareColors.navy,
        borderRadius: BorderRadius.circular(CityCareRadius.xl),
        boxShadow: CityCareShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(CityCareRadius.xl),
          onTap: () =>
              context.push('${Routes.queue(a.id)}?org=${a.organizationId}'),
          child: Padding(
            padding: const EdgeInsets.all(CityCareSpacing.lg + 2),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CityCareColors.lime,
                    borderRadius: BorderRadius.circular(CityCareRadius.md),
                  ),
                  child: Text(
                    a.tokenNumber == null ? '…' : '#${a.tokenNumber}',
                    style: const TextStyle(
                      color: CityCareColors.navy,
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                    ),
                  ),
                ),
                const SizedBox(width: CityCareSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR TOKEN TODAY',
                        style: TextStyle(
                          color: CityCareColors.mint,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          a.doctorName,
                          a.clinicName,
                        ].whereType<String>().join(' · '),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: CityCareColors.lime,
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
      style: IconButton.styleFrom(
        backgroundColor: CityCareColors.surface,
        side: const BorderSide(color: CityCareColors.border),
      ),
      onPressed: () async {
        await context.push(Routes.notifications);
        if (mounted) setState(() => _unread = 0);
      },
      icon: Badge(
        isLabelVisible: _unread > 0,
        label: Text(_unread > 9 ? '9+' : '$_unread'),
        backgroundColor: CityCareColors.danger,
        child: const Icon(
          Icons.notifications_none_rounded,
          color: CityCareColors.ink,
        ),
      ),
    );
  }
}
