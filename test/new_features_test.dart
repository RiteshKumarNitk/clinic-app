import 'dart:convert';

import 'package:clinic_app/core/network/api_client.dart';
import 'package:clinic_app/core/storage/token_storage.dart';
import 'package:clinic_app/core/utils/clinic_time.dart';
import 'package:clinic_app/features/appointments/data/appointment_models.dart';
import 'package:clinic_app/features/appointments/data/appointment_repository.dart';
import 'package:clinic_app/features/clinics/data/clinic_models.dart';
import 'package:clinic_app/features/clinics/data/clinic_repository.dart';
import 'package:clinic_app/features/notifications/data/notifications_repository.dart';
import 'package:clinic_app/features/records/data/records_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_flow_test.dart' show pumpApp;
import 'support.dart';

const _session = SessionTokens(accessToken: 'a', refreshToken: 'r');

ApiClient _api(FakeBackend b) => ApiClient(
  storage: InMemoryTokenStorage(_session),
  httpClient: b.client,
  baseUrl: 'https://x.test/api',
);

void main() {
  setUpAll(ClinicTime.ensureInitialized);

  group('family booking', () {
    test('booking for an existing member sends patientId', () {
      final body = BookingRequest(
        organizationId: orgId,
        doctorId: doctorId,
        scheduledStart: DateTime.utc(2026, 10, 9, 4),
        patient: const PatientDetails(firstName: 'Asha', lastName: 'Verma'),
        bookingFor: const BookingFor.member('p-mom'),
      ).toJson();
      expect(body['patientId'], 'p-mom');
      expect(body.containsKey('dependent'), isFalse);
    });

    test('booking for a new member sends dependent details', () {
      final body = BookingRequest(
        organizationId: orgId,
        doctorId: doctorId,
        scheduledStart: DateTime.utc(2026, 10, 9, 4),
        patient: const PatientDetails(firstName: 'Asha', lastName: 'Verma'),
        bookingFor: const BookingFor.newMember(
          NewDependent(
            firstName: ' Ravi ',
            lastName: 'Verma',
            relation: 'CHILD',
          ),
        ),
      ).toJson();
      expect(body['dependent'], {
        'firstName': 'Ravi',
        'lastName': 'Verma',
        'relation': 'CHILD',
      });
      expect(body.containsKey('patientId'), isFalse);
    });

    test('family list comes from /patient/family for the clinic', () async {
      final b = FakeBackend()..serveEverything();
      final repo = AppointmentRepository(_api(b), ClinicRepository(_api(b)));
      final family = await repo.family(orgId);
      expect(family.single.name, 'Sita Verma');
      expect(family.single.relationLabel, 'Mother');
      expect(b.requests.last.url.queryParameters['organizationId'], orgId);
    });
  });

  test(
    'reschedule posts the new slot and returns the new appointment',
    () async {
      final b = FakeBackend()
        ..on('POST /orgs/$orgId/appointments/appt-1/reschedule', (req) {
          expect(jsonDecode(req.body), {
            'scheduledStart': '2026-10-09T04:30:00.000Z',
            'appointmentTypeId': typeId,
          });
          return jsonResponse({
            'previousId': 'appt-1',
            'appointment': appointmentRow(id: 'appt-2'),
          }, 201);
        });
      final repo = AppointmentRepository(_api(b), ClinicRepository(_api(b)));
      final fresh = await repo.reschedule(
        organizationId: orgId,
        appointmentId: 'appt-1',
        scheduledStart: DateTime.utc(2026, 10, 9, 4, 30),
        appointmentTypeId: typeId,
      );
      expect(fresh.id, 'appt-2');
    },
  );

  group('discovery filters + near me', () {
    test('near me sends rounded coordinates and filters', () async {
      final b = FakeBackend()..serveEverything();
      await ClinicRepository(_api(b)).list(
        near: (lat: 12.971923, lng: 77.641234),
        city: 'Bengaluru',
        orgType: 'HOSPITAL',
      );
      final q = b.requests.single.url.queryParameters;
      expect(q['lat'], '12.97');
      expect(q['lng'], '77.64');
      expect(q['city'], 'Bengaluru');
      expect(q['orgType'], 'HOSPITAL');
    });

    test('distance and coordinates parse', () {
      final c = ClinicSummary.fromJson({
        'id': orgId,
        'slug': 's',
        'name': 'N',
        'locations': [
          {'city': 'Pune', 'latitude': 18.5, 'longitude': 73.8},
        ],
        'distanceKm': 2.4,
      });
      expect(c.distanceKm, 2.4);
      final l = ClinicLocation.fromJson({
        'id': 'l',
        'name': 'Main',
        'latitude': 18.5,
        'longitude': 73.8,
      });
      expect(l.hasCoordinates, isTrue);
    });
  });

  group('records', () {
    test('patients never see an unsigned draft', () {
      expect(VisitSummary.fromJson({'assessment': 'Draft'}), isNull);
      final signed = VisitSummary.fromJson({
        'signedAt': '2026-10-07T05:00:00.000Z',
        'assessment': 'Viral fever',
        'prescriptions': [
          {
            'id': 'rx-1',
            'issuedAt': '2026-10-07T05:00:00.000Z',
            'items': [
              {
                'drugName': 'Paracetamol',
                'strength': '500 mg',
                'form': 'tablet',
                'dosage': '1 tablet',
                'frequency': 'Three times a day',
                'durationDays': 3,
                'foodInstruction': 'AFTER',
              },
            ],
          },
        ],
      })!;
      final item = signed.prescriptions.single.items.single;
      expect(item.title, 'Paracetamol 500 mg tablet');
      expect(
        item.directions,
        '1 tablet · Three times a day · 3 days · After food',
      );
    });
  });

  test('notification inbox merges clinics and counts unread', () async {
    final b = FakeBackend()..serveEverything();
    final repo = NotificationsRepository(
      _api(b),
      AppointmentRepository(_api(b), ClinicRepository(_api(b))),
    );
    final inbox = await repo.inbox();
    expect(inbox.unreadCount, 1);
    expect(inbox.items.single.appointmentId, 'appt-1');
    expect(inbox.items.single.clinicName, contains('Demo Clinic'));
  });

  group('screens', () {
    testWidgets('confirm booking asks who the visit is for', (tester) async {
      final (_, backend) = await pumpApp(tester, session: _session);
      backend.on(
        'POST /patient/appointments',
        (_) => jsonResponse(appointmentRow(id: 'appt-new'), 201),
      );
      final router =
          tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
              as dynamic;
      router.push('/doctors/$doctorId');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Book appointment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose a time'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ChoiceChip).first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Continue ·'));
      await tester.pumpAndSettle();

      expect(find.text('Who is this visit for?'), findsOneWidget);
      expect(find.text('Sita Verma (Mother)'), findsOneWidget);
      await tester.tap(find.text('Sita Verma (Mother)'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm booking'));
      await tester.pumpAndSettle();

      final booking = backend.requests.lastWhere(
        (r) => r.url.path.endsWith('/patient/appointments'),
      );
      expect(jsonDecode(booking.body)['patientId'], 'p-mom');
      expect(find.text('Appointment confirmed'), findsOneWidget);
    });

    testWidgets('appointment details offers change time and quick actions', (
      tester,
    ) async {
      await pumpApp(tester, session: _session);
      final router =
          tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
              as dynamic;
      router.push('/appointments/$orgId/appt-1');
      await tester.pumpAndSettle();
      expect(find.text('Change time'), findsOneWidget);
      expect(find.text('Add to calendar'), findsOneWidget);
      expect(find.text('Directions'), findsOneWidget);
      expect(find.text('Call clinic'), findsOneWidget);

      await tester.tap(find.text('Change time'));
      await tester.pumpAndSettle();
      expect(find.text('Choose a new time'), findsOneWidget);
    });

    testWidgets('Find shows filter chips from the server', (tester) async {
      final (_, backend) = await pumpApp(tester, session: _session);
      await tester.tap(find.text('Find'));
      await tester.pumpAndSettle();
      expect(find.text('Near me'), findsOneWidget);
      expect(find.text('City'), findsOneWidget);
      await tester.tap(find.text('Hospital'));
      await tester.pumpAndSettle();
      final last = backend.requests.lastWhere(
        (r) => r.url.path.endsWith('/public/organizations'),
      );
      expect(last.url.queryParameters['orgType'], 'HOSPITAL');
    });

    testWidgets('notification bell opens the inbox', (tester) async {
      await pumpApp(tester, session: _session);
      await tester.tap(find.byTooltip('Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('An appointment was booked.'), findsOneWidget);
    });
  });
}
