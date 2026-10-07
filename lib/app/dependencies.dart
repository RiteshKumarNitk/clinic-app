import 'package:flutter/foundation.dart';

import '../core/auth/auth_controller.dart';
import '../core/auth/google_auth_gateway.dart';
import '../core/network/api_client.dart';
import '../core/storage/token_storage.dart';
import '../features/appointments/data/appointment_repository.dart';
import '../features/clinics/data/clinic_repository.dart';
import '../features/doctors/data/doctor_repository.dart';
import '../features/queue/data/queue_repository.dart';

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
  });

  factory Dependencies.production() => Dependencies.from(
    storage: SecureTokenStorage(),
    google: GoogleSignInGateway(),
  );

  factory Dependencies.from({
    required TokenStorage storage,
    required GoogleAuthGateway google,
    ApiClient? api,
  }) {
    final client = api ?? ApiClient(storage: storage);
    final clinics = ClinicRepository(client);
    return Dependencies(
      api: client,
      auth: AuthController(api: client, storage: storage, google: google),
      clinics: clinics,
      doctors: DoctorRepository(client),
      appointments: AppointmentRepository(client, clinics),
      queue: QueueRepository(client),
    );
  }

  final ApiClient api;
  final AuthController auth;
  final ClinicRepository clinics;
  final DoctorRepository doctors;
  final AppointmentRepository appointments;
  final QueueRepository queue;
  final AppointmentsChanged appointmentsChanged = AppointmentsChanged();
}
