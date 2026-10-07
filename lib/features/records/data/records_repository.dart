import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../appointments/data/appointment_repository.dart';
import 'records_models.dart';

/// Visit summaries and prescriptions the patient's doctors have issued.
class RecordsRepository {
  RecordsRepository(this._api, this._appointments);

  final ApiClient _api;
  final AppointmentRepository _appointments;

  /// The signed summary for one appointment, or null if the doctor hasn't
  /// written (or signed) one yet.
  Future<VisitSummary?> visitSummary({
    required String organizationId,
    required String appointmentId,
  }) async {
    try {
      final json = await _api.get(
        '/orgs/${Uri.encodeComponent(organizationId)}'
        '/appointments/${Uri.encodeComponent(appointmentId)}/consultation',
        auth: Auth.required,
      );
      return VisitSummary.fromJson(json);
    } on ApiException catch (e) {
      // No consultation row yet comes back as an empty body / 404.
      if (e.isNotFound || e.code == 'MALFORMED') return null;
      rethrow;
    }
  }

  /// Every prescription across the patient's clinics, newest first.
  Future<List<Prescription>> prescriptions() async {
    final clinics = await _appointments.myClinics();
    final perClinic = await Future.wait(
      clinics.map((c) async {
        final rows = await _api.getList(
          '/orgs/${Uri.encodeComponent(c.id)}/prescriptions',
          auth: Auth.required,
          query: const {'pageSize': '50'},
        );
        return rows.map((r) => Prescription.fromJson(r, clinicName: c.name));
      }),
    );
    return perClinic.expand((x) => x).toList()
      ..sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
  }
}
