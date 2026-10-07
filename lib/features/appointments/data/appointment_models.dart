import '../../../core/utils/json.dart';

/// A bookable instant from `GET /api/public/doctors/:id/slots`.
class Slot {
  const Slot({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  factory Slot.fromJson(Json j) =>
      Slot(start: date(j, 'start')!, end: date(j, 'end')!);
}

/// One day of availability — the server computed every slot (doctor hours,
/// exceptions, lead time, existing bookings); the app only renders them.
class SlotDay {
  const SlotDay({
    required this.slots,
    required this.timezone,
    required this.durationMinutes,
    required this.slotsHiddenByLeadTime,
    required this.bookingLeadTimeMinutes,
  });

  final List<Slot> slots;
  final String timezone;
  final int durationMinutes;
  final int slotsHiddenByLeadTime;
  final int bookingLeadTimeMinutes;

  factory SlotDay.fromJson(Json j) => SlotDay(
    slots: objList(j, 'slots')
        .where((s) => date(s, 'start') != null && date(s, 'end') != null)
        .map(Slot.fromJson)
        .toList(growable: false),
    timezone: str(j, 'timezone') ?? 'Asia/Kolkata',
    durationMinutes: intOrNull(j, 'durationMinutes') ?? 15,
    slotsHiddenByLeadTime: intOrNull(j, 'slotsHiddenByLeadTime') ?? 0,
    bookingLeadTimeMinutes: intOrNull(j, 'bookingLeadTimeMinutes') ?? 0,
  );
}

/// Demographics the booking API requires on a patient's first booking at a
/// clinic (ignored by the server afterwards).
class PatientDetails {
  const PatientDetails({
    required this.firstName,
    required this.lastName,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String? phone;

  Json toJson() => {
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
  };
}

/// Relations the backend accepts for a family member.
const familyRelations = <String, String>{
  'SPOUSE': 'Spouse',
  'FATHER': 'Father',
  'MOTHER': 'Mother',
  'CHILD': 'Child',
  'GUARDIAN': 'Guardian',
  'OTHER': 'Other',
};

/// Someone the patient books for — `GET /api/patient/family`.
class FamilyMember {
  const FamilyMember({
    required this.patientId,
    required this.firstName,
    required this.lastName,
    this.relation,
  });

  final String patientId;
  final String firstName;
  final String lastName;
  final String? relation;

  String get name => '$firstName $lastName'.trim();
  String? get relationLabel => familyRelations[relation];

  factory FamilyMember.fromJson(Json j) => FamilyMember(
    patientId: reqStr(j, 'patientId'),
    firstName: str(j, 'firstName') ?? '',
    lastName: str(j, 'lastName') ?? '',
    relation: str(j, 'relation'),
  );
}

/// A family member being added at booking time (no record yet).
class NewDependent {
  const NewDependent({
    required this.firstName,
    required this.lastName,
    required this.relation,
  });

  final String firstName;
  final String lastName;
  final String relation;

  Json toJson() => {
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    'relation': relation,
  };
}

/// Who a booking is for: the patient themself (both null), an existing family
/// member ([patientId]) or a new one ([dependent]).
class BookingFor {
  const BookingFor.self() : patientId = null, dependent = null;
  const BookingFor.member(String this.patientId) : dependent = null;
  const BookingFor.newMember(NewDependent this.dependent) : patientId = null;

  final String? patientId;
  final NewDependent? dependent;

  Json toJson() => {
    if (patientId != null) 'patientId': patientId,
    if (dependent != null) 'dependent': dependent!.toJson(),
  };
}

/// Body of `POST /api/patient/appointments`.
class BookingRequest {
  const BookingRequest({
    required this.organizationId,
    required this.doctorId,
    required this.scheduledStart,
    required this.patient,
    this.appointmentTypeId,
    this.locationId,
    this.reason,
    this.bookingFor = const BookingFor.self(),
  });

  final String organizationId;
  final String doctorId;
  final BookingFor bookingFor;

  /// Must be one of the instants the slots endpoint returned.
  final DateTime scheduledStart;
  final PatientDetails patient;
  final String? appointmentTypeId;
  final String? locationId;
  final String? reason;

  Json toJson() => {
    'organizationId': organizationId,
    'doctorId': doctorId,
    'scheduledStart': scheduledStart.toUtc().toIso8601String(),
    'patient': patient.toJson(),
    if (appointmentTypeId != null) 'appointmentTypeId': appointmentTypeId,
    if (locationId != null) 'locationId': locationId,
    if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
    ...bookingFor.toJson(),
  };
}

enum AppointmentStatus {
  requested,
  confirmed,
  checkedIn,
  waiting,
  inConsultation,
  completed,
  cancelled,
  noShow,
  rescheduled,
  unknown,
}

AppointmentStatus parseStatus(String? v) => switch (v) {
  'REQUESTED' => AppointmentStatus.requested,
  'CONFIRMED' => AppointmentStatus.confirmed,
  'CHECKED_IN' => AppointmentStatus.checkedIn,
  'WAITING' => AppointmentStatus.waiting,
  'IN_CONSULTATION' => AppointmentStatus.inConsultation,
  'COMPLETED' => AppointmentStatus.completed,
  'CANCELLED' => AppointmentStatus.cancelled,
  'NO_SHOW' => AppointmentStatus.noShow,
  'RESCHEDULED' => AppointmentStatus.rescheduled,
  _ => AppointmentStatus.unknown,
};

extension AppointmentStatusX on AppointmentStatus {
  bool get isActive => const {
    AppointmentStatus.requested,
    AppointmentStatus.confirmed,
    AppointmentStatus.checkedIn,
    AppointmentStatus.waiting,
    AppointmentStatus.inConsultation,
  }.contains(this);

  String get label => switch (this) {
    AppointmentStatus.requested => 'Requested',
    AppointmentStatus.confirmed => 'Confirmed',
    AppointmentStatus.checkedIn => 'Checked in',
    AppointmentStatus.waiting => 'Waiting',
    AppointmentStatus.inConsultation => 'In consultation',
    AppointmentStatus.completed => 'Completed',
    AppointmentStatus.cancelled => 'Cancelled',
    AppointmentStatus.noShow => 'Missed',
    AppointmentStatus.rescheduled => 'Rescheduled',
    AppointmentStatus.unknown => 'Booked',
  };
}

/// An appointment row — list (`GET /api/orgs/:orgId/appointments`), detail
/// (`…/appointments/:id`) and the booking response share this shape; detail
/// adds the appointment type and full location.
class Appointment {
  const Appointment({
    required this.id,
    required this.organizationId,
    required this.doctorId,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.timezone,
    required this.status,
    required this.isToken,
    this.doctorName,
    this.patientName,
    this.locationId,
    this.locationName,
    this.locationAddress,
    this.locationCity,
    this.appointmentTypeId,
    this.appointmentTypeName,
    this.reason,
    this.tokenNumber,
    this.queueState,
    this.cancellationReason,
    this.clinicName,
    this.clinicSlug,
    this.clinicLogoUrl,
  });

  /// appointmentId
  final String id;
  final String organizationId;
  final String doctorId;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String timezone;
  final AppointmentStatus status;

  /// A same-day queue token rather than a timed slot.
  final bool isToken;
  final String? doctorName;
  final String? patientName;
  final String? locationId;
  final String? locationName;
  final String? locationAddress;
  final String? locationCity;
  final String? appointmentTypeId;
  final String? appointmentTypeName;
  final String? reason;
  final int? tokenNumber;
  final String? queueState;
  final String? cancellationReason;

  // Filled in by the repository from the patient's clinic list.
  final String? clinicName;
  final String? clinicSlug;
  final String? clinicLogoUrl;

  bool get hasQueue => isToken || tokenNumber != null;

  factory Appointment.fromJson(Json j) {
    final doctor = obj(j, 'doctor');
    final patient = obj(j, 'patient');
    final location = obj(j, 'location');
    final type = obj(j, 'appointmentType');
    final queue = obj(j, 'queueEntry');
    final patientName = patient == null
        ? null
        : [
            str(patient, 'firstName'),
            str(patient, 'lastName'),
          ].whereType<String>().join(' ');
    return Appointment(
      id: reqStr(j, 'id'),
      organizationId: reqStr(j, 'organizationId'),
      doctorId: reqStr(j, 'doctorId'),
      scheduledStart: date(j, 'scheduledStart')!,
      scheduledEnd: date(j, 'scheduledEnd') ?? date(j, 'scheduledStart')!,
      timezone: str(j, 'timezone') ?? 'Asia/Kolkata',
      status: parseStatus(str(j, 'status')),
      isToken: str(j, 'bookingKind') == 'SAME_DAY_TOKEN',
      doctorName: doctor == null ? null : str(doctor, 'displayName'),
      patientName: patientName == null || patientName.isEmpty
          ? null
          : patientName,
      locationId: str(j, 'locationId'),
      locationName: location == null ? null : str(location, 'name'),
      locationAddress: location == null ? null : str(location, 'addressLine1'),
      locationCity: location == null ? null : str(location, 'city'),
      appointmentTypeId: str(j, 'appointmentTypeId'),
      appointmentTypeName: type == null ? null : str(type, 'name'),
      reason: str(j, 'reason'),
      tokenNumber: queue == null ? null : intOrNull(queue, 'tokenNumber'),
      queueState: queue == null ? null : str(queue, 'state'),
      cancellationReason: str(j, 'cancellationReason'),
    );
  }

  Appointment withClinic({
    String? name,
    String? slug,
    String? logoUrl,
    String? typeName,
  }) => Appointment(
    id: id,
    organizationId: organizationId,
    doctorId: doctorId,
    scheduledStart: scheduledStart,
    scheduledEnd: scheduledEnd,
    timezone: timezone,
    status: status,
    isToken: isToken,
    doctorName: doctorName,
    patientName: patientName,
    locationId: locationId,
    locationName: locationName,
    locationAddress: locationAddress,
    locationCity: locationCity,
    appointmentTypeId: appointmentTypeId,
    appointmentTypeName: appointmentTypeName ?? typeName,
    reason: reason,
    tokenNumber: tokenNumber,
    queueState: queueState,
    cancellationReason: cancellationReason,
    clinicName: name ?? clinicName,
    clinicSlug: slug ?? clinicSlug,
    clinicLogoUrl: logoUrl ?? clinicLogoUrl,
  );
}

/// A clinic the patient belongs to — `GET /api/orgs` (filtered to PATIENT).
class MyClinic {
  const MyClinic({
    required this.id,
    required this.name,
    this.slug,
    this.logoUrl,
    required this.role,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? slug;
  final String? logoUrl;
  final String role;
  final bool isActive;

  factory MyClinic.fromJson(Json j) => MyClinic(
    id: reqStr(j, 'id'),
    name: str(j, 'name') ?? 'Clinic',
    slug: str(j, 'slug'),
    logoUrl: str(j, 'logoUrl'),
    role: str(j, 'role') ?? '',
    isActive: boolOr(j, 'isActive', true),
  );
}
