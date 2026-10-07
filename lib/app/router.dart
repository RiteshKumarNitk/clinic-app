import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_controller.dart';
import '../features/appointments/data/appointment_models.dart';
import '../features/appointments/presentation/appointment_details_screen.dart';
import '../features/appointments/presentation/appointments_screen.dart';
import '../features/appointments/presentation/booking_confirmed_screen.dart';
import '../features/appointments/presentation/booking_draft.dart';
import '../features/appointments/presentation/appointment_type_screen.dart';
import '../features/appointments/presentation/confirm_booking_screen.dart';
import '../features/appointments/presentation/slot_picker_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/clinics/presentation/clinic_details_screen.dart';
import '../features/clinics/presentation/find_healthcare_screen.dart';
import '../features/doctors/presentation/doctor_details_screen.dart';
import '../features/home/home_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/queue/presentation/live_queue_screen.dart';
import '../features/queue/presentation/token_confirm_screen.dart';
import '../features/records/presentation/records_screen.dart';
import '../shared/app_shell.dart';

class Routes {
  Routes._();

  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
  static const appointments = '/appointments';
  static const find = '/find';
  static const profile = '/profile';

  static String clinic(String slug) => '/clinics/${Uri.encodeComponent(slug)}';
  static String doctor(String id) => '/doctors/$id';
  static String bookType(String doctorId) => '/doctors/$doctorId/book/type';
  static String bookTime(String doctorId) => '/doctors/$doctorId/book/time';
  static String bookConfirm(String doctorId) =>
      '/doctors/$doctorId/book/confirm';
  static String token(String doctorId) => '/doctors/$doctorId/token';
  static const bookingConfirmed = '/booking-confirmed';
  static String appointment(String orgId, String appointmentId) =>
      '/appointments/$orgId/$appointmentId';
  static String queue(String appointmentId) => '/queue/$appointmentId';
  static String reschedule(String orgId, String appointmentId) =>
      '/appointments/$orgId/$appointmentId/reschedule';
  static const notifications = '/notifications';
  static const records = '/records';
  static const findDoctors = '/find?mode=doctors';
  static String findWithQuery(String q) =>
      '/find?q=${Uri.encodeQueryComponent(q)}';
}

final _rootKey = GlobalKey<NavigatorState>();

/// One guard for the whole app, driven by the single [AuthController]:
///  * restoring  → splash (never a premature login screen)
///  * signed out → Continue with Google
///  * signed in  → every screen opens directly; no screen asks again.
///  * guest      → discovery opens; personal routes need sign-in.
GoRouter buildRouter(AuthController auth) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final at = state.matchedLocation;
      switch (auth.status) {
        case AuthStatus.unknown:
          return at == Routes.splash ? null : Routes.splash;
        case AuthStatus.unauthenticated:
          return at == Routes.login ? null : Routes.login;
        case AuthStatus.authenticated:
          return at == Routes.splash || at == Routes.login ? Routes.home : null;
        case AuthStatus.guest:
          if (at == Routes.splash || at == Routes.login) return Routes.home;
          // Safety net — the UI asks guests to sign in before these.
          return _isPersonal(at) ? Routes.home : null;
      }
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.appointments,
                builder: (_, _) => const AppointmentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.find,
                builder: (_, state) => FindHealthcareScreen(
                  // A new search or mode from Home re-keys the screen.
                  key: ValueKey(state.uri.toString()),
                  initialQuery: state.uri.queryParameters['q'],
                  initialDoctors:
                      state.uri.queryParameters['mode'] == 'doctors',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/clinics/:slug',
        builder: (_, state) =>
            ClinicDetailsScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/doctors/:doctorId',
        builder: (_, state) =>
            DoctorDetailsScreen(doctorId: state.pathParameters['doctorId']!),
        routes: [
          GoRoute(
            parentNavigatorKey: _rootKey,
            path: 'book/type',
            builder: (_, state) =>
                _withDraft(state, (d) => AppointmentTypeScreen(draft: d)),
          ),
          GoRoute(
            parentNavigatorKey: _rootKey,
            path: 'book/time',
            builder: (_, state) =>
                _withDraft(state, (d) => SlotPickerScreen(draft: d)),
          ),
          GoRoute(
            parentNavigatorKey: _rootKey,
            path: 'book/confirm',
            builder: (_, state) =>
                _withDraft(state, (d) => ConfirmBookingScreen(draft: d)),
          ),
          GoRoute(
            parentNavigatorKey: _rootKey,
            path: 'token',
            builder: (_, state) =>
                _withDraft(state, (d) => TokenConfirmScreen(draft: d)),
          ),
        ],
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.bookingConfirmed,
        builder: (_, state) {
          final appt = state.extra;
          return appt is BookingResult
              ? BookingConfirmedScreen(result: appt)
              : const AppointmentsScreen();
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/appointments/:orgId/:appointmentId',
        builder: (_, state) => AppointmentDetailsScreen(
          organizationId: state.pathParameters['orgId']!,
          appointmentId: state.pathParameters['appointmentId']!,
          preview: state.extra is Appointment
              ? state.extra as Appointment
              : null,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/appointments/:orgId/:appointmentId/reschedule',
        builder: (_, state) => _withDraft(
          state,
          (d) => SlotPickerScreen(draft: d),
          fallback: () => AppointmentDetailsScreen(
            organizationId: state.pathParameters['orgId']!,
            appointmentId: state.pathParameters['appointmentId']!,
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.notifications,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: Routes.records,
        builder: (_, _) => const RecordsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/queue/:appointmentId',
        builder: (_, state) => LiveQueueScreen(
          appointmentId: state.pathParameters['appointmentId']!,
          organizationId: state.uri.queryParameters['org'],
        ),
      ),
    ],
  );
}

/// Routes that act on the patient's own account (booking, tokens,
/// appointments, queue) — never reachable as a guest.
bool _isPersonal(String location) =>
    location == Routes.notifications ||
    location == Routes.records ||
    location.startsWith('/queue/') ||
    location.startsWith('/appointments/') ||
    location == Routes.bookingConfirmed ||
    RegExp(r'^/doctors/[^/]+/(book|token)').hasMatch(location);

/// Booking steps carry their in-progress draft as `extra`. If it's missing
/// (e.g. process death), restart from the doctor rather than crash.
Widget _withDraft(
  GoRouterState state,
  Widget Function(BookingDraft) build, {
  Widget Function()? fallback,
}) {
  final draft = state.extra;
  if (draft is BookingDraft) return build(draft);
  return fallback?.call() ??
      DoctorDetailsScreen(doctorId: state.pathParameters['doctorId']!);
}
