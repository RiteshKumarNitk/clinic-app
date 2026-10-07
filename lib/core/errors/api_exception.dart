/// Every failure the network layer can produce, normalised.
///
/// [code] is the backend's machine-readable error code (e.g. `SLOT_TAKEN`,
/// `TOKEN_BOOKING_CLOSED`) or a client-side one (`NETWORK`, `TIMEOUT`).
/// [message] is never shown verbatim — screens go through [friendlyMessage].
class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.status,
    this.details,
  });

  final String code;
  final String message;
  final int? status;
  final Object? details;

  bool get isNetwork => code == 'NETWORK' || code == 'TIMEOUT';
  bool get isUnauthenticated => status == 401 || code == 'NOT_AUTHENTICATED';
  bool get isNotFound => status == 404 || code == 'NOT_FOUND';

  @override
  String toString() => 'ApiException($code, $status): $message';
}

/// Backend codes whose server message is written for patients and safe to
/// show as-is (they explain a booking rule, not a fault).
const _patientSafeCodes = {
  'TOKEN_BOOKING_NOT_OPEN',
  'TOKEN_BOOKING_CLOSED',
  'TOKEN_BOOKING_UNAVAILABLE',
  'TOKEN_LIMIT_REACHED',
  'OUTSIDE_CANCELLATION_WINDOW',
  'FORBIDDEN',
};

const _slotConflictCodes = {
  'APPOINTMENT_SLOT_TAKEN',
  'CONFLICT',
  'OUTSIDE_AVAILABILITY',
};

/// The chosen time was taken or became unbookable — offer another time.
bool isSlotConflict(Object error) =>
    error is ApiException && _slotConflictCodes.contains(error.code);

/// Turns any error into one calm sentence for a patient. Never leaks
/// exception class names, HTTP codes or stack traces.
String friendlyMessage(Object error, {required String fallback}) {
  if (error is ApiException) {
    if (error.isNetwork) {
      return 'You appear to be offline. Check your connection and try again.';
    }
    if (error.isUnauthenticated) {
      return 'Your session has ended. Please continue with Google again.';
    }
    if (isSlotConflict(error)) {
      return 'This time is no longer available. Please choose another time.';
    }
    if (error.code == 'RATE_LIMITED') {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (_patientSafeCodes.contains(error.code) && error.message.isNotEmpty) {
      return error.message;
    }
  }
  return fallback;
}
