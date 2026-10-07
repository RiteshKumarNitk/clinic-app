import '../../clinics/data/clinic_models.dart';
import '../../doctors/data/doctor_models.dart';
import '../data/appointment_models.dart';

/// The booking in progress, carried from step to step. Every id comes from
/// the backend; nothing is computed locally.
class BookingDraft {
  const BookingDraft({
    required this.doctor,
    this.type,
    this.slot,
    this.timezone,
    this.rescheduleOf,
  });

  final DoctorDetail doctor;

  /// Set when picking a new time for an existing appointment.
  final Appointment? rescheduleOf;
  bool get isReschedule => rescheduleOf != null;
  final AppointmentType? type;
  final Slot? slot;

  /// Clinic timezone, as reported by the slots endpoint.
  final String? timezone;

  String get organizationId => doctor.clinic.ref.id;
  String get clinicName => doctor.clinic.ref.name;

  /// The branch the visit happens at. Clinics with a single branch (the
  /// common case) need no choice; otherwise the server default applies.
  ClinicLocation? get location => doctor.clinic.locations.length == 1
      ? doctor.clinic.locations.first
      : null;

  BookingDraft copyWith({
    AppointmentType? type,
    Slot? slot,
    String? timezone,
  }) => BookingDraft(
    doctor: doctor,
    type: type ?? this.type,
    slot: slot ?? this.slot,
    timezone: timezone ?? this.timezone,
    rescheduleOf: rescheduleOf,
  );
}

/// What the confirmation screen shows: the server's appointment plus the
/// context the patient chose it in.
class BookingResult {
  const BookingResult({required this.appointment, required this.draft});

  final Appointment appointment;
  final BookingDraft draft;
}
