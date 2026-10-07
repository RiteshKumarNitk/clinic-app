import 'package:clinic_app/core/utils/clinic_time.dart';
import 'package:clinic_app/features/appointments/data/appointment_models.dart';
import 'package:clinic_app/features/appointments/presentation/appointments_screen.dart';
import 'package:clinic_app/features/clinics/data/clinic_models.dart';
import 'package:clinic_app/features/doctors/data/doctor_models.dart';
import 'package:clinic_app/features/queue/data/queue_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  setUpAll(ClinicTime.ensureInitialized);

  group('Clinic API parsing (real production payloads)', () {
    test('clinic list keeps organizationId, slug, cities and doctor count', () {
      final page = Paged.fromJson(
        fixture('organizations.json'),
        ClinicSummary.fromJson,
      );
      expect(page.items, isNotEmpty);
      final c = page.items.first;
      expect(c.id, orgId);
      expect(c.slug, 'demo-clinic');
      expect(c.cities, ['Bengaluru']);
      expect(c.doctorCount, 1);
      expect(c.verification, VerificationStatus.draft);
      expect(page.hasMore, isFalse);
    });

    test('pagination math', () {
      final p = Paged<int>(items: const [1], total: 45, page: 2, pageSize: 20);
      expect(p.hasMore, isTrue);
      final last = Paged<int>(
        items: const [1],
        total: 45,
        page: 3,
        pageSize: 20,
      );
      expect(last.hasMore, isFalse);
    });

    test('clinic details: locations, doctors, appointment types', () {
      final d = ClinicDetail.fromJson(fixture('organization_detail.json'));
      expect(d.id, orgId);
      expect(d.publicPhone, '+91 90000 00001');
      expect(d.about, isNull);
      expect(d.locations.single.id, locationId);
      expect(d.locations.single.address, 'Bengaluru');
      expect(d.doctors.single.id, doctorId);
      expect(d.doctors.single.bookingMode, BookingMode.both);
      expect(d.doctors.single.clinic?.id, orgId);
      expect(d.appointmentTypes.single.id, typeId);
      expect(d.appointmentTypes.single.durationMinutes, 15);
    });
  });

  group('Doctor parsing', () {
    test('doctor details carry clinic, types and booking mode', () {
      final d = DoctorDetail.fromJson(fixture('doctor_detail.json'));
      expect(d.id, doctorId);
      expect(d.specialty, 'General Medicine');
      expect(d.bookingMode.offersSlots, isTrue);
      expect(d.bookingMode.offersTokens, isTrue);
      expect(d.consultationDurationMin, 15);
      expect(d.clinic.ref.id, orgId);
      expect(d.clinic.appointmentTypes.single.id, typeId);
      expect(d.clinic.locations.single.id, locationId);
    });

    test('cross-clinic doctor search rows carry their clinic', () {
      final page = Paged.fromJson(
        fixture('doctors.json'),
        (j) => DoctorSummary.fromJson(j),
      );
      expect(page.items.single.clinic?.slug, 'demo-clinic');
    });

    test('booking modes', () {
      expect(parseBookingMode('SCHEDULED').offersTokens, isFalse);
      expect(parseBookingMode('SAME_DAY_TOKEN').offersSlots, isFalse);
    });
  });

  group('Availability', () {
    test('slots are UTC instants from the server, shown in clinic time', () {
      final day = SlotDay.fromJson(fixture('slots.json'));
      expect(day.slots, isNotEmpty);
      expect(day.timezone, 'Asia/Kolkata');
      expect(day.durationMinutes, 15);
      final first = day.slots.first;
      expect(first.start.isUtc, isTrue);
      expect(first.start, DateTime.utc(2026, 10, 8, 3, 30));
      // 03:30 UTC == 09:00 IST
      expect(ClinicTime.time(first.start, day.timezone), '9:00 AM');
    });

    test('empty day explains the lead time', () {
      final day = SlotDay.fromJson({
        'slots': [],
        'timezone': 'Asia/Kolkata',
        'durationMinutes': 15,
        'slotsHiddenByLeadTime': 3,
        'bookingLeadTimeMinutes': 120,
      });
      expect(day.slots, isEmpty);
      expect(day.slotsHiddenByLeadTime, 3);
    });
  });

  group('Booking', () {
    test('booking request body matches selfBookAppointmentSchema', () {
      final body = BookingRequest(
        organizationId: orgId,
        doctorId: doctorId,
        scheduledStart: DateTime.utc(2026, 10, 8, 3, 30),
        appointmentTypeId: typeId,
        locationId: locationId,
        reason: '  ',
        patient: const PatientDetails(firstName: ' Asha ', lastName: 'Verma'),
      ).toJson();
      expect(body, {
        'organizationId': orgId,
        'doctorId': doctorId,
        'scheduledStart': '2026-10-08T03:30:00.000Z',
        'patient': {'firstName': 'Asha', 'lastName': 'Verma'},
        'appointmentTypeId': typeId,
        'locationId': locationId,
      });
    });

    test('appointment response (bare row from POST /patient/appointments)', () {
      final row = appointmentRow()
        ..remove('doctor')
        ..remove('patient')
        ..remove('location');
      final a = Appointment.fromJson(row);
      expect(a.id, 'appt-1');
      expect(a.organizationId, orgId);
      expect(a.status, AppointmentStatus.confirmed);
      expect(a.isToken, isFalse);
      expect(a.doctorName, isNull);
    });

    test('appointment list row with relations and token', () {
      final a = Appointment.fromJson(
        appointmentRow(
          bookingKind: 'SAME_DAY_TOKEN',
          status: 'WAITING',
          queueEntry: {'tokenNumber': 7, 'state': 'WAITING'},
        ),
      );
      expect(a.doctorName, 'Dr. Demo Sharma');
      expect(a.patientName, 'Asha Verma');
      expect(a.locationName, 'Demo Clinic — Main Branch');
      expect(a.tokenNumber, 7);
      expect(a.hasQueue, isTrue);
      expect(a.status.isActive, isTrue);
    });

    test('upcoming vs past split', () {
      final now = DateTime.utc(2026, 10, 7, 6);
      final list = [
        Appointment.fromJson(appointmentRow(id: 'future')),
        Appointment.fromJson(
          appointmentRow(
            id: 'old',
            start: '2026-10-01T04:00:00.000Z',
            end: '2026-10-01T04:15:00.000Z',
            status: 'COMPLETED',
          ),
        ),
        Appointment.fromJson(
          appointmentRow(id: 'cancelled', status: 'CANCELLED'),
        ),
        // Today's token whose queue already started is still upcoming.
        Appointment.fromJson(
          appointmentRow(
            id: 'token-today',
            bookingKind: 'SAME_DAY_TOKEN',
            status: 'WAITING',
            start: '2026-10-07T03:30:00.000Z',
            end: '2026-10-07T03:45:00.000Z',
          ),
        ),
      ];
      final split = splitAppointments(list, now: now);
      expect(split.upcoming.map((a) => a.id), ['token-today', 'future']);
      expect(split.past.map((a) => a.id), ['cancelled', 'old']);
    });
  });

  group('Queue', () {
    test('token window', () {
      final w = TokenWindow.fromJson(fixture('token_window.json'));
      expect(w.timezone, 'Asia/Kolkata');
      expect(w.opensAt, '07:00');
      expect(w.queueStartAt, '09:00');
      expect(w.status, isNotEmpty);
    });

    test('token booking response (reused)', () {
      final t = TokenBooking.fromJson({
        'appointmentId': 'appt-t',
        'entryId': 'q-1',
        'tokenNumber': 12,
        'reused': true,
        'doctorName': 'Dr. Demo Sharma',
        'queueDate': '2026-10-07',
        'queueStartAt': '09:00',
      });
      expect(t.queueEntryId, 'q-1');
      expect(t.tokenNumber, 12);
      expect(t.reused, isTrue);
    });

    test('token request has no date', () {
      final body = const TokenRequest(
        organizationId: orgId,
        doctorId: doctorId,
        patient: PatientDetails(firstName: 'Asha', lastName: 'Verma'),
      ).toJson();
      expect(body.containsKey('date'), isFalse);
      expect(body['organizationId'], orgId);
    });

    test('token status uses server numbers', () {
      final s = TokenStatus.fromJson(tokenStatusJson());
      expect(s.tokenNumber, 12);
      expect(s.nowServingToken, 9);
      expect(s.ahead, 2);
      expect(s.adviceTone, AdviceTone.wait);
      expect(s.isFinished, isFalse);
      expect(
        TokenStatus.fromJson(tokenStatusJson(state: 'COMPLETED')).isFinished,
        isTrue,
      );
      // Skipped can be recalled — keep polling.
      expect(
        TokenStatus.fromJson(tokenStatusJson(state: 'SKIPPED')).isFinished,
        isFalse,
      );
    });
  });

  test('fees are minor units', () {
    expect(formatFee(50000), '₹500');
    expect(formatFee(null), isNull);
  });
}
