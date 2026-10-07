import '../../../core/utils/json.dart';
import '../../doctors/data/doctor_models.dart';

export '../../../core/network/paged.dart';

enum VerificationStatus { draft, pending, verified, rejected, unknown }

VerificationStatus parseVerification(String? v) => switch (v) {
  'VERIFIED' => VerificationStatus.verified,
  'PENDING_VERIFICATION' => VerificationStatus.pending,
  'DRAFT' => VerificationStatus.draft,
  'REJECTED' => VerificationStatus.rejected,
  _ => VerificationStatus.unknown,
};

String? orgTypeLabel(String? v) => switch (v) {
  'HOSPITAL' => 'Hospital',
  'CLINIC' => 'Clinic',
  'DIAGNOSTIC_CENTER' => 'Diagnostic centre',
  'POLYCLINIC' => 'Polyclinic',
  'OTHER' => null,
  _ => null,
};

/// A card in the clinic list — `GET /api/public/organizations`.
class ClinicSummary {
  const ClinicSummary({
    required this.id,
    required this.slug,
    required this.name,
    this.tagline,
    this.logoUrl,
    this.orgType,
    required this.verification,
    required this.cities,
    required this.doctorCount,
  });

  /// organizationId — the identity. [slug] addresses the public detail route.
  final String id;
  final String slug;
  final String name;
  final String? tagline;
  final String? logoUrl;
  final String? orgType;
  final VerificationStatus verification;
  final List<String> cities;
  final int doctorCount;

  factory ClinicSummary.fromJson(Json j) => ClinicSummary(
    id: reqStr(j, 'id'),
    slug: reqStr(j, 'slug'),
    name: reqStr(j, 'name'),
    tagline: str(j, 'tagline'),
    logoUrl: str(j, 'logoUrl'),
    orgType: str(j, 'orgType'),
    verification: parseVerification(str(j, 'verificationStatus')),
    cities: objList(j, 'locations')
        .map((l) => str(l, 'city'))
        .whereType<String>()
        .toSet()
        .toList(growable: false),
    doctorCount: intOrNull(obj(j, '_count') ?? const {}, 'doctorProfiles') ?? 0,
  );
}

class ClinicLocation {
  const ClinicLocation({
    required this.id,
    required this.name,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.phone,
  });

  final String id;
  final String name;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final String? phone;

  /// Only the parts the clinic actually filled in.
  String get address => [
    addressLine1,
    addressLine2,
    [city, state].whereType<String>().join(', '),
    postalCode,
  ].whereType<String>().where((s) => s.isNotEmpty).join(', ');

  factory ClinicLocation.fromJson(Json j) => ClinicLocation(
    id: reqStr(j, 'id'),
    name: str(j, 'name') ?? 'Main branch',
    addressLine1: str(j, 'addressLine1'),
    addressLine2: str(j, 'addressLine2'),
    city: str(j, 'city'),
    state: str(j, 'state'),
    postalCode: str(j, 'postalCode'),
    country: str(j, 'country'),
    phone: str(j, 'phone'),
  );
}

/// A clinic's bookable category, e.g. "General Consultation — 15 min".
class AppointmentType {
  const AppointmentType({
    required this.id,
    required this.name,
    required this.durationMinutes,
  });

  /// appointmentTypeId
  final String id;
  final String name;
  final int durationMinutes;

  factory AppointmentType.fromJson(Json j) => AppointmentType(
    id: reqStr(j, 'id'),
    name: str(j, 'name') ?? 'Consultation',
    durationMinutes: intOrNull(j, 'durationMinutes') ?? 15,
  );
}

/// `GET /api/public/organizations/:slug`.
class ClinicDetail {
  const ClinicDetail({
    required this.id,
    required this.slug,
    required this.name,
    this.tagline,
    this.about,
    this.logoUrl,
    this.coverImageUrl,
    this.orgType,
    this.publicPhone,
    this.publicEmail,
    this.website,
    required this.verification,
    required this.locations,
    required this.doctors,
    required this.appointmentTypes,
  });

  final String id;
  final String slug;
  final String name;
  final String? tagline;
  final String? about;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? orgType;
  final String? publicPhone;
  final String? publicEmail;
  final String? website;
  final VerificationStatus verification;
  final List<ClinicLocation> locations;
  final List<DoctorSummary> doctors;
  final List<AppointmentType> appointmentTypes;

  factory ClinicDetail.fromJson(Json j) {
    final ref = ClinicRef(
      id: reqStr(j, 'id'),
      slug: str(j, 'slug'),
      name: reqStr(j, 'name'),
      logoUrl: str(j, 'logoUrl'),
    );
    return ClinicDetail(
      id: ref.id,
      slug: reqStr(j, 'slug'),
      name: ref.name,
      tagline: str(j, 'tagline'),
      about: str(j, 'about'),
      logoUrl: ref.logoUrl,
      coverImageUrl: str(j, 'coverImageUrl'),
      orgType: str(j, 'orgType'),
      publicPhone: str(j, 'publicPhone'),
      publicEmail: str(j, 'publicEmail'),
      website: str(j, 'website'),
      verification: parseVerification(str(j, 'verificationStatus')),
      locations: objList(
        j,
        'locations',
      ).map(ClinicLocation.fromJson).toList(growable: false),
      doctors: objList(j, 'doctorProfiles')
          .map((d) => DoctorSummary.fromJson(d, clinic: ref))
          .toList(growable: false),
      appointmentTypes: objList(
        j,
        'appointmentTypes',
      ).map(AppointmentType.fromJson).toList(growable: false),
    );
  }
}
