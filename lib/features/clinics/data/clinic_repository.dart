import '../../../core/network/api_client.dart';
import 'clinic_models.dart';

/// Public clinic discovery. Search and pagination are server-side; the app
/// never holds more than the pages the patient has scrolled through.
class ClinicRepository {
  ClinicRepository(this._api);

  final ApiClient _api;

  /// Short-lived detail cache so moving between a clinic, its doctors and the
  /// booking flow doesn't refetch the same profile.
  final Map<String, (DateTime, ClinicDetail)> _details = {};
  static const _ttl = Duration(minutes: 5);

  Future<Paged<ClinicSummary>> list({
    String? query,
    String? city,
    int page = 1,
    int pageSize = 20,
  }) async {
    final json = await _api.get(
      '/public/organizations',
      query: {
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
        if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
        'page': '$page',
        'pageSize': '$pageSize',
      },
    );
    return Paged.fromJson(json, ClinicSummary.fromJson);
  }

  Future<ClinicDetail> detail(String slug, {bool refresh = false}) async {
    final cached = _details[slug];
    if (!refresh &&
        cached != null &&
        DateTime.now().difference(cached.$1) < _ttl) {
      return cached.$2;
    }
    final json = await _api.get(
      '/public/organizations/${Uri.encodeComponent(slug)}',
    );
    final detail = ClinicDetail.fromJson(json);
    _details[slug] = (DateTime.now(), detail);
    return detail;
  }
}
