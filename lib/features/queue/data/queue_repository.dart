import '../../../core/network/api_client.dart';
import 'queue_models.dart';

/// Same-day tokens and live queue status — the existing backend queue, read
/// per appointment so each token stays tied to its own clinic and doctor.
class QueueRepository {
  QueueRepository(this._api);

  final ApiClient _api;

  Future<TokenBooking> bookToken(TokenRequest request) async {
    final json = await _api.post(
      '/patient/appointments/token',
      body: request.toJson(),
    );
    return TokenBooking.fromJson(json);
  }

  Future<TokenStatus> status(String appointmentId) async {
    final json = await _api.get(
      '/patient/token-status',
      query: {'appointmentId': appointmentId},
      auth: Auth.required,
    );
    return TokenStatus.fromJson(json);
  }
}
