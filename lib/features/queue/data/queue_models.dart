import '../../../core/utils/json.dart';
import '../../appointments/data/appointment_models.dart';

/// `GET /api/public/doctors/:id/token-window` — whether a same-day token can
/// be taken right now. The same computation the booking endpoint enforces.
class TokenWindow {
  const TokenWindow({
    required this.status,
    required this.bookable,
    required this.date,
    required this.timezone,
    required this.opensAt,
    required this.closesAt,
    required this.queueStartAt,
    this.reason,
    this.errorCode,
  });

  /// OPEN | NOT_YET_OPEN | CLOSED | UNAVAILABLE
  final String status;
  final bool bookable;
  final String date;
  final String timezone;
  final String opensAt;
  final String closesAt;
  final String queueStartAt;
  final String? reason;
  final String? errorCode;

  factory TokenWindow.fromJson(Json j) => TokenWindow(
    status: str(j, 'status') ?? 'UNAVAILABLE',
    bookable: boolOr(j, 'bookable', false),
    date: str(j, 'date') ?? '',
    timezone: str(j, 'timezone') ?? 'Asia/Kolkata',
    opensAt: str(j, 'opensAt') ?? '',
    closesAt: str(j, 'closesAt') ?? '',
    queueStartAt: str(j, 'queueStartAt') ?? '',
    reason: str(j, 'reason'),
    errorCode: str(j, 'errorCode'),
  );
}

/// Body of `POST /api/patient/appointments/token`. No date: a token is always
/// for the clinic's today, decided by the server.
class TokenRequest {
  const TokenRequest({
    required this.organizationId,
    required this.doctorId,
    required this.patient,
    this.locationId,
    this.reason,
  });

  final String organizationId;
  final String doctorId;
  final PatientDetails patient;
  final String? locationId;
  final String? reason;

  Json toJson() => {
    'organizationId': organizationId,
    'doctorId': doctorId,
    'patient': patient.toJson(),
    if (locationId != null) 'locationId': locationId,
    if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
  };
}

/// Response of the token booking. [reused] is true when the patient already
/// held a token for this doctor today — the server returns that one.
class TokenBooking {
  const TokenBooking({
    required this.appointmentId,
    required this.queueEntryId,
    required this.tokenNumber,
    required this.reused,
    this.doctorName,
    this.queueDate,
    this.queueStartAt,
  });

  final String appointmentId;
  final String queueEntryId;
  final int tokenNumber;
  final bool reused;
  final String? doctorName;
  final String? queueDate;
  final String? queueStartAt;

  factory TokenBooking.fromJson(Json j) => TokenBooking(
    appointmentId: reqStr(j, 'appointmentId'),
    queueEntryId: reqStr(j, 'entryId'),
    tokenNumber: intOrNull(j, 'tokenNumber') ?? 0,
    reused: boolOr(j, 'reused', false),
    doctorName: str(j, 'doctorName'),
    queueDate: str(j, 'queueDate'),
    queueStartAt: str(j, 'queueStartAt'),
  );
}

enum AdviceTone { wait, actNow, seeReception, done, problem }

/// `GET /api/patient/token-status?appointmentId=` — every number here is the
/// server's; the app never computes queue positions.
class TokenStatus {
  const TokenStatus({
    required this.appointmentId,
    required this.queueEntryId,
    required this.tokenNumber,
    required this.state,
    required this.ahead,
    this.nowServingToken,
    this.doctorName,
    this.queueDate,
    this.queueStartAt,
    this.appointmentStatus,
    this.advice,
    required this.adviceTone,
  });

  final String appointmentId;
  final String queueEntryId;
  final int tokenNumber;

  /// WAITING | CALLED | IN_CONSULTATION | COMPLETED | SKIPPED | HOLD | NO_SHOW
  final String state;
  final int ahead;
  final int? nowServingToken;
  final String? doctorName;
  final String? queueDate;
  final String? queueStartAt;
  final String? appointmentStatus;
  final String? advice;
  final AdviceTone adviceTone;

  /// Nothing left to wait for — stop polling.
  bool get isFinished =>
      state == 'COMPLETED' ||
      state == 'NO_SHOW' ||
      appointmentStatus == 'CANCELLED' ||
      appointmentStatus == 'RESCHEDULED';

  String get stateLabel => switch (state) {
    'WAITING' => 'Waiting',
    'CALLED' => "You're being called",
    'IN_CONSULTATION' => 'In consultation',
    'COMPLETED' => 'Completed',
    'SKIPPED' => 'Skipped',
    'HOLD' => 'On hold',
    'NO_SHOW' => 'Missed',
    _ => state,
  };

  factory TokenStatus.fromJson(Json j) => TokenStatus(
    appointmentId: reqStr(j, 'appointmentId'),
    queueEntryId: reqStr(j, 'queueEntryId'),
    tokenNumber: intOrNull(j, 'tokenNumber') ?? 0,
    state: str(j, 'state') ?? 'WAITING',
    ahead: intOrNull(j, 'ahead') ?? 0,
    nowServingToken: intOrNull(j, 'nowServingToken'),
    doctorName: str(j, 'doctorName'),
    queueDate: str(j, 'queueDate'),
    queueStartAt: str(j, 'queueStartAt'),
    appointmentStatus: str(j, 'appointmentStatus'),
    advice: str(j, 'advice'),
    adviceTone: switch (str(j, 'adviceTone')) {
      'ACT_NOW' => AdviceTone.actNow,
      'SEE_RECEPTION' => AdviceTone.seeReception,
      'DONE' => AdviceTone.done,
      'PROBLEM' => AdviceTone.problem,
      _ => AdviceTone.wait,
    },
  );
}
