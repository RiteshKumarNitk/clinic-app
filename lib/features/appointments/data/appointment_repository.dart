import '../../../core/network/api_client.dart';
import '../../../core/utils/clinic_time.dart';
import '../../clinics/data/clinic_repository.dart';
import 'appointment_models.dart';

/// Availability, booking and the patient's own appointments.
///
/// Appointments are tenant-scoped on the backend: the patient's clinics come
/// from `GET /api/orgs` (a PATIENT membership is created by their first
/// booking), then each clinic's appointment list is read. The server returns
/// only this patient's rows.
class AppointmentRepository {
  AppointmentRepository(this._api, this._clinics);

  final ApiClient _api;
  final ClinicRepository _clinics;

  Future<SlotDay> slots({
    required String doctorId,
    required DateTime day,
    String? appointmentTypeId,
  }) async {
    final json = await _api.get(
      '/public/doctors/${Uri.encodeComponent(doctorId)}/slots',
      query: {
        'date': ClinicTime.apiDate(day),
        if (appointmentTypeId != null) 'appointmentTypeId': appointmentTypeId,
      },
    );
    return SlotDay.fromJson(json);
  }

  Future<Appointment> book(BookingRequest request) async {
    final json = await _api.post(
      '/patient/appointments',
      body: request.toJson(),
    );
    return Appointment.fromJson(json);
  }

  Future<List<MyClinic>> myClinics() async {
    final list = await _api.getList('/orgs', auth: Auth.required);
    return list
        .map(MyClinic.fromJson)
        .where((c) => c.role == 'PATIENT' && c.isActive)
        .toList(growable: false);
  }

  /// Every appointment of this patient across clinics, soonest first.
  Future<List<Appointment>> myAppointments({DateTime? now}) async {
    final clinics = await myClinics();
    if (clinics.isEmpty) return const [];
    final reference = (now ?? DateTime.now()).toUtc();
    final perClinic = await Future.wait(
      clinics.map((c) => _forClinic(c, reference)),
    );
    final all = perClinic.expand((x) => x).toList()
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
    return all;
  }

  Future<List<Appointment>> _forClinic(MyClinic clinic, DateTime now) async {
    final path = '/orgs/${Uri.encodeComponent(clinic.id)}/appointments';
    // Two windows so a long history never pushes upcoming visits past the
    // server's 100-row cap: everything from yesterday on (catches today's
    // tokens whose queue already started), and the past year.
    final yesterday = now.subtract(const Duration(days: 1));
    final results = await Future.wait([
      _api.getList(
        path,
        auth: Auth.required,
        query: {'from': yesterday.toIso8601String(), 'limit': '100'},
      ),
      _api.getList(
        path,
        auth: Auth.required,
        query: {
          'from': now.subtract(const Duration(days: 365)).toIso8601String(),
          'to': yesterday.toIso8601String(),
          'limit': '100',
        },
      ),
    ]);
    final typeNames = await _typeNames(clinic.slug);
    return results
        .expand((rows) => rows)
        .map(Appointment.fromJson)
        .map(
          (a) => a.withClinic(
            name: clinic.name,
            slug: clinic.slug,
            logoUrl: clinic.logoUrl,
            typeName: typeNames[a.appointmentTypeId],
          ),
        )
        .toList(growable: false);
  }

  /// Appointment type names come from the clinic's public profile (the list
  /// endpoint returns only the id). Best effort: an unpublished clinic just
  /// yields no labels.
  Future<Map<String?, String>> _typeNames(String? slug) async {
    if (slug == null) return const {};
    try {
      final detail = await _clinics.detail(slug);
      return {for (final t in detail.appointmentTypes) t.id: t.name};
    } catch (_) {
      return const {};
    }
  }

  Future<Appointment> detail({
    required String organizationId,
    required String appointmentId,
  }) async {
    final results = await Future.wait([
      _api.get(
        '/orgs/${Uri.encodeComponent(organizationId)}'
        '/appointments/${Uri.encodeComponent(appointmentId)}',
        auth: Auth.required,
      ),
      myClinics().catchError((_) => <MyClinic>[]),
    ]);
    final appt = Appointment.fromJson(results[0] as Map<String, dynamic>);
    final clinics = results[1] as List<MyClinic>;
    final clinic = clinics.where((c) => c.id == organizationId).firstOrNull;
    return clinic == null
        ? appt
        : appt.withClinic(
            name: clinic.name,
            slug: clinic.slug,
            logoUrl: clinic.logoUrl,
          );
  }

  Future<void> cancel({
    required String organizationId,
    required String appointmentId,
    required String reason,
  }) async {
    await _api.post(
      '/orgs/${Uri.encodeComponent(organizationId)}'
      '/appointments/${Uri.encodeComponent(appointmentId)}/cancel',
      body: {'reason': reason},
    );
  }
}
