import '../../../core/utils/json.dart';

String? foodInstructionLabel(String? v) => switch (v) {
  'BEFORE' => 'Before food',
  'AFTER' => 'After food',
  'WITH_FOOD' => 'With food',
  _ => null,
};

/// One medicine on a prescription.
class PrescriptionItem {
  const PrescriptionItem({
    required this.drugName,
    this.strength,
    this.form,
    this.dosage,
    this.frequency,
    this.durationDays,
    this.foodInstruction,
    this.instructions,
  });

  final String drugName;
  final String? strength;
  final String? form;
  final String? dosage;
  final String? frequency;
  final int? durationDays;
  final String? foodInstruction;
  final String? instructions;

  /// "500 mg tablet"
  String get title => [drugName, strength, form].whereType<String>().join(' ');

  /// "1 tablet · twice a day · 5 days · after food"
  String get directions => [
    dosage,
    frequency,
    if (durationDays != null) '$durationDays days',
    foodInstructionLabel(foodInstruction),
  ].whereType<String>().join(' · ');

  factory PrescriptionItem.fromJson(Json j) => PrescriptionItem(
    drugName: str(j, 'drugName') ?? 'Medicine',
    strength: str(j, 'strength'),
    form: str(j, 'form'),
    dosage: str(j, 'dosage'),
    frequency: str(j, 'frequency'),
    durationDays: intOrNull(j, 'durationDays'),
    foodInstruction: str(j, 'foodInstruction'),
    instructions: str(j, 'instructions'),
  );
}

class Prescription {
  const Prescription({
    required this.id,
    required this.issuedAt,
    required this.items,
    this.notes,
    this.doctorName,
    this.patientName,
    this.clinicName,
  });

  final String id;
  final DateTime issuedAt;
  final List<PrescriptionItem> items;
  final String? notes;
  final String? doctorName;
  final String? patientName;
  final String? clinicName;

  factory Prescription.fromJson(Json j, {String? clinicName}) {
    final doctor = obj(j, 'doctor');
    final patient = obj(j, 'patient');
    final patientName = patient == null
        ? null
        : [
            str(patient, 'firstName'),
            str(patient, 'lastName'),
          ].whereType<String>().join(' ');
    return Prescription(
      id: reqStr(j, 'id'),
      issuedAt: date(j, 'issuedAt') ?? DateTime.now().toUtc(),
      items: objList(j, 'items').map(PrescriptionItem.fromJson).toList(),
      notes: str(j, 'notes'),
      doctorName: doctor == null ? null : str(doctor, 'displayName'),
      patientName: patientName == null || patientName.isEmpty
          ? null
          : patientName,
      clinicName: clinicName,
    );
  }
}

/// The doctor's signed visit summary for one appointment.
class VisitSummary {
  const VisitSummary({
    required this.signedAt,
    this.assessment,
    this.plan,
    this.instructions,
    this.testsAdvised,
    this.followUpDate,
    required this.prescriptions,
  });

  final DateTime signedAt;
  final String? assessment;
  final String? plan;
  final String? instructions;
  final String? testsAdvised;
  final DateTime? followUpDate;
  final List<Prescription> prescriptions;

  bool get isEmpty =>
      assessment == null &&
      plan == null &&
      instructions == null &&
      testsAdvised == null &&
      followUpDate == null &&
      prescriptions.isEmpty;

  /// Null for a draft — patients only ever see what the doctor signed.
  static VisitSummary? fromJson(Json? j) {
    if (j == null) return null;
    final signed = date(j, 'signedAt');
    if (signed == null) return null;
    return VisitSummary(
      signedAt: signed,
      assessment: str(j, 'assessment'),
      plan: str(j, 'plan'),
      instructions: str(j, 'instructions'),
      testsAdvised: str(j, 'testsAdvised'),
      followUpDate: date(j, 'followUpDate'),
      prescriptions: objList(
        j,
        'prescriptions',
      ).map((p) => Prescription.fromJson(p)).toList(),
    );
  }
}
