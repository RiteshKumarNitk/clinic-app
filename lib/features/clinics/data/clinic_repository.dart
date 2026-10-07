import '../../../core/network/api_client.dart';
import '../../../core/network/memo_cache.dart';
import 'clinic_models.dart';

/// Public clinic discovery. Search and pagination are server-side; the app
/// never holds more than the pages the patient has scrolled through.
class ClinicRepository {
  ClinicRepository(this._api);

  final ApiClient _api;

  /// Short-lived caches so moving between Home, Find, a clinic, its doctors
  /// and the booking flow doesn't refetch the same data.
  final _lists = MemoCache<Paged<ClinicSummary>>(
    ttl: const Duration(minutes: 1),
  );
  final _details = MemoCache<ClinicDetail>(ttl: const Duration(minutes: 5));

  final _filters = MemoCache<DiscoveryFilters>(
    ttl: const Duration(minutes: 10),
  );

  /// [near] ranks by distance from (lat, lng). Coordinates are rounded to
  /// ~1 km before leaving the phone — enough for ranking, kinder to privacy,
  /// and it lets nearby patients share the edge cache.
  Future<Paged<ClinicSummary>> list({
    String? query,
    String? city,
    String? orgType,
    ({double lat, double lng})? near,
    int page = 1,
    int pageSize = 20,
    bool refresh = false,
  }) {
    final params = {
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (city != null && city.trim().isNotEmpty) 'city': city.trim(),
      if (orgType != null) 'orgType': orgType,
      if (near != null) 'lat': near.lat.toStringAsFixed(2),
      if (near != null) 'lng': near.lng.toStringAsFixed(2),
      'page': '$page',
      'pageSize': '$pageSize',
    };
    return _lists.get(params.toString(), () async {
      final json = await _api.get('/public/organizations', query: params);
      return Paged.fromJson(json, ClinicSummary.fromJson);
    }, refresh: refresh);
  }

  Future<ClinicDetail> detail(String slug, {bool refresh = false}) {
    return _details.get(slug, () async {
      final json = await _api.get(
        '/public/organizations/${Uri.encodeComponent(slug)}',
      );
      return ClinicDetail.fromJson(json);
    }, refresh: refresh);
  }

  Future<DiscoveryFilters> filters() => _filters.get('all', () async {
    return DiscoveryFilters.fromJson(await _api.get('/public/filters'));
  });
}
