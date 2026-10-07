import '../../../core/utils/json.dart';
import '../../clinics/data/clinic_models.dart';

enum BookingMode { scheduled, sameDayToken, both }

BookingMode parseBookingMode(String? v) => switch (v) {
  'SAME_DAY_TOKEN' => BookingMode.sameDayToken,
  'BOTH' => BookingMode.both,
  _ => BookingMode.scheduled,
};

extension BookingModeX on BookingMode {
  bool get offersSlots => this != BookingMode.sameDayToken;
  bool get offersTokens => this != BookingMode.scheduled;
}

/// The clinic a doctor belongs to, as embedded in doctor payloads.
class ClinicRef {
  const ClinicRef({
    required this.id,
    this.slug,
    required this.name,
    this.logoUrl,
  });

  /// organizationId
  final String id;
  final String? slug;
  final String name;
  final String? logoUrl;

  static ClinicRef? fromJson(Json? j) => j == null
      ? null
      : ClinicRef(
          id: reqStr(j, 'id'),
          slug: str(j, 'slug'),
          name: str(j, 'name') ?? 'Clinic',
          logoUrl: str(j, 'logoUrl'),
        );
}

/// Doctor card — from a clinic detail or `GET /api/public/doctors`.
class DoctorSummary {
  const DoctorSummary({
    required this.id,
    required this.displayName,
    this.specialty,
    this.photoUrl,
    this.yearsOfExperience,
    required this.languages,
    this.consultationFeeMinor,
    required this.bookingMode,
    this.clinic,
  });

  /// doctorId
  final String id;
  final String displayName;
  final String? specialty;
  final String? photoUrl;
  final int? yearsOfExperience;
  final List<String> languages;
  final int? consultationFeeMinor;
  final BookingMode bookingMode;
  final ClinicRef? clinic;

  factory DoctorSummary.fromJson(Json j, {ClinicRef? clinic}) => DoctorSummary(
    id: reqStr(j, 'id'),
    displayName: str(j, 'displayName') ?? 'Doctor',
    specialty: str(j, 'specialty'),
    photoUrl: str(j, 'photoUrl'),
    yearsOfExperience: intOrNull(j, 'yearsOfExperience'),
    languages: strList(j, 'languages'),
    consultationFeeMinor: intOrNull(j, 'consultationFeeMinor'),
    bookingMode: parseBookingMode(str(j, 'bookingMode')),
    clinic: ClinicRef.fromJson(obj(j, 'organization')) ?? clinic,
  );
}

/// The doctor's clinic as embedded in `GET /api/public/doctors/:id`.
class DoctorClinic {
  const DoctorClinic({
    required this.ref,
    this.publicPhone,
    this.publicEmail,
    required this.locations,
    required this.appointmentTypes,
  });

  final ClinicRef ref;
  final String? publicPhone;
  final String? publicEmail;
  final List<ClinicLocation> locations;
  final List<AppointmentType> appointmentTypes;

  factory DoctorClinic.fromJson(Json j) => DoctorClinic(
    ref: ClinicRef.fromJson(j)!,
    publicPhone: str(j, 'publicPhone'),
    publicEmail: str(j, 'publicEmail'),
    locations: objList(
      j,
      'locations',
    ).map(ClinicLocation.fromJson).toList(growable: false),
    appointmentTypes: objList(
      j,
      'appointmentTypes',
    ).map(AppointmentType.fromJson).toList(growable: false),
  );
}

/// `GET /api/public/doctors/:doctorId`.
class DoctorDetail {
  const DoctorDetail({
    required this.id,
    required this.displayName,
    this.specialty,
    this.bio,
    this.qualifications,
    this.photoUrl,
    this.yearsOfExperience,
    required this.languages,
    this.consultationFeeMinor,
    required this.bookingMode,
    this.consultationDurationMin,
    required this.clinic,
  });

  final String id;
  final String displayName;
  final String? specialty;
  final String? bio;
  final String? qualifications;
  final String? photoUrl;
  final int? yearsOfExperience;
  final List<String> languages;
  final int? consultationFeeMinor;
  final BookingMode bookingMode;
  final int? consultationDurationMin;
  final DoctorClinic clinic;

  factory DoctorDetail.fromJson(Json j) => DoctorDetail(
    id: reqStr(j, 'id'),
    displayName: str(j, 'displayName') ?? 'Doctor',
    specialty: str(j, 'specialty'),
    bio: str(j, 'bio'),
    qualifications: str(j, 'qualifications'),
    photoUrl: str(j, 'photoUrl'),
    yearsOfExperience: intOrNull(j, 'yearsOfExperience'),
    languages: strList(j, 'languages'),
    consultationFeeMinor: intOrNull(j, 'consultationFeeMinor'),
    bookingMode: parseBookingMode(str(j, 'bookingMode')),
    consultationDurationMin: intOrNull(j, 'consultationDurationMin'),
    clinic: DoctorClinic.fromJson(obj(j, 'organization') ?? const {}),
  );
}
