import 'package:flutter/foundation.dart';

import '../core/auth/auth_controller.dart';
import '../core/auth/google_auth_gateway.dart';
import '../core/network/api_client.dart';
import '../core/push/push_service.dart';
import '../core/storage/token_storage.dart';
import '../features/appointments/data/appointment_repository.dart';
import '../features/clinics/data/clinic_repository.dart';
import '../features/doctors/data/doctor_repository.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/queue/data/queue_repository.dart';
import '../features/records/data/records_repository.dart';

/// Tells appointment-showing screens to reload after a booking or a
/// cancellation, without coupling them to the screens that made the change.
class AppointmentsChanged extends ChangeNotifier {
  int _version = 0;
  int get version => _version;

  void bump() {
    _version++;
    notifyListeners();
  }
}

/// The app's object graph, built once.
class Dependencies {
  Dependencies({
    required this.api,
    required this.auth,
    required this.clinics,
    required this.doctors,
    required this.appointments,
    required this.queue,
    required this.records,
    required this.notifications,
    required this.push,
  }) {
    // Register this phone for push whenever someone signs in; unregister on
    // logout while the session can still authorise the call.
    var wasAuthenticated = false;
    auth.addListener(() {
      if (auth.isAuthenticated && !wasAuthenticated) push.registerDevice();
      wasAuthenticated = auth.isAuthenticated;
    });
    auth.beforeLogout = push.unregisterDevice;
  }

  factory Dependencies.production() {
    final storage = SecureTokenStorage();
    final api = ApiClient(storage: storage);
    return Dependencies.from(
      storage: storage,
      google: GoogleSignInGateway(),
      api: api,
      push: FirebasePushService(api),
    );
  }

  factory Dependencies.from({
    required TokenStorage storage,
    required GoogleAuthGateway google,
    ApiClient? api,
    PushService? push,
  }) {
    final client = api ?? ApiClient(storage: storage);
    final clinics = ClinicRepository(client);
    final appointments = AppointmentRepository(client, clinics);
    return Dependencies(
      api: client,
      auth: AuthController(api: client, storage: storage, google: google),
      clinics: clinics,
      doctors: DoctorRepository(client),
      appointments: appointments,
      queue: QueueRepository(client),
      records: RecordsRepository(client, appointments),
      notifications: NotificationsRepository(client, appointments),
      push: push ?? NoopPushService(),
    );
  }

  final ApiClient api;
  final AuthController auth;
  final ClinicRepository clinics;
  final DoctorRepository doctors;
  final AppointmentRepository appointments;
  final QueueRepository queue;
  final RecordsRepository records;
  final NotificationsRepository notifications;
  final PushService push;
  final AppointmentsChanged appointmentsChanged = AppointmentsChanged();
}
