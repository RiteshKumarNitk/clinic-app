import '../../../core/network/api_client.dart';
import '../../../core/network/memo_cache.dart';
import '../../clinics/data/clinic_models.dart';
import '../../queue/data/queue_models.dart';
import 'doctor_models.dart';

class DoctorRepository {
  DoctorRepository(this._api);

  final ApiClient _api;

  /// Server-side doctor search across all public clinics (name/specialty).
  Future<Paged<DoctorSummary>> list({
    String? query,
    String? specialty,
    String? clinicSlug,
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = await _api.get(
      '/public/doctors',
      query: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
        if (clinicSlug != null) 'organizationSlug': clinicSlug,
        'page': '$page',
        'pageSize': '$pageSize',
      },
    );
    return Paged.fromJson(json, (j) => DoctorSummary.fromJson(j));
  }

  final _details = MemoCache<DoctorDetail>(ttl: const Duration(minutes: 5));

  Future<DoctorDetail> detail(String doctorId) {
    return _details.get(doctorId, () async {
      final json = await _api.get(
        '/public/doctors/${Uri.encodeComponent(doctorId)}',
      );
      return DoctorDetail.fromJson(json);
    });
  }

  Future<TokenWindow> tokenWindow(String doctorId) async {
    final json = await _api.get(
      '/public/doctors/${Uri.encodeComponent(doctorId)}/token-window',
    );
    return TokenWindow.fromJson(json);
  }
}
