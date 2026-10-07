import 'dart:convert';
import 'dart:io';

import 'package:clinic_app/core/auth/google_auth_gateway.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

/// Shapes below mirror the backend's Prisma selects exactly
/// (appointments/service.ts listAppointments/getAppointment,
/// tokens/service.ts getPatientTokenStatus, users/service.ts getMe).
const orgId = 'f5697798-9e58-4e37-9cdd-e565efd03465';
const doctorId = 'a7f71aeb-81c9-4fc6-a81b-0a7942a95f4b';
const typeId = '894a7a6f-8280-4c69-966f-efc77dd3c97d';
const locationId = '35ff2275-77b4-4478-867a-ca9b20eeefef';

Map<String, dynamic> meJson() => {
  'id': 'u-1',
  'email': 'asha@example.com',
  'fullName': 'Asha Verma',
  'phone': null,
  'avatarUrl': null,
  'isGuest': false,
  'memberships': [],
};

Map<String, dynamic> appointmentRow({
  String id = 'appt-1',
  String status = 'CONFIRMED',
  String? start,
  String? end,
  String bookingKind = 'SCHEDULED',
  Map<String, dynamic>? queueEntry,
}) {
  // Default: two days from now, so "upcoming" stays upcoming whenever the
  // suite runs.
  final s = DateTime.now().toUtc().add(const Duration(days: 2));
  return {
    'id': id,
    'organizationId': orgId,
    'patientId': 'p-1',
    'doctorId': doctorId,
    'locationId': locationId,
    'appointmentTypeId': typeId,
    'scheduledStart': start ?? s.toIso8601String(),
    'scheduledEnd': end ?? s.add(const Duration(minutes: 15)).toIso8601String(),
    'timezone': 'Asia/Kolkata',
    'status': status,
    'reason': null,
    'bookingKind': bookingKind,
    'patient': {'id': 'p-1', 'firstName': 'Asha', 'lastName': 'Verma'},
    'doctor': {'id': doctorId, 'displayName': 'Dr. Demo Sharma'},
    'location': {
      'id': locationId,
      'name': 'Demo Clinic — Main Branch',
      'city': 'Bengaluru',
    },
    'queueEntry': queueEntry,
  };
}

Map<String, dynamic> myOrgsJson() => {
  'data': [
    {
      'id': orgId,
      'name': 'Demo Clinic (synthetic data — not real patients)',
      'slug': 'demo-clinic',
      'timezone': 'Asia/Kolkata',
      'isActive': true,
      'role': 'PATIENT',
      'capabilities': [],
    },
  ],
};

Map<String, dynamic> tokenStatusJson({String state = 'WAITING'}) => {
  'appointmentId': 'appt-t',
  'queueEntryId': 'q-1',
  'tokenNumber': 12,
  'state': state,
  'ahead': 2,
  'nowServingToken': 9,
  'doctorName': 'Dr. Demo Sharma',
  'queueDate': '2026-10-07',
  'queueStartAt': '09:00',
  'bookingKind': 'SAME_DAY_TOKEN',
  'appointmentStatus': 'WAITING',
  'advice': 'You are in the queue. Please wait in the waiting area.',
  'adviceTone': 'WAIT',
};

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

/// A scripted backend: route → handler. Records every request.
class FakeBackend {
  final requests = <http.Request>[];
  final routes = <String, http.Response Function(http.Request)>{};

  void on(String methodAndPath, http.Response Function(http.Request) h) =>
      routes[methodAndPath] = h;

  MockClient get client => MockClient((req) async {
    requests.add(req);
    final path = req.url.path.replaceFirst('/api', '');
    final handler = routes['${req.method} $path'];
    if (handler == null) {
      return jsonResponse({
        'error': {'code': 'NOT_FOUND', 'message': 'no route $path'},
      }, 404);
    }
    return handler(req);
  });

  /// Every public + patient route the app uses, answered with real-shape data.
  void serveEverything() {
    on(
      'GET /public/organizations',
      (_) => jsonResponse(fixture('organizations.json')),
    );
    on(
      'GET /public/organizations/demo-clinic',
      (_) => jsonResponse(fixture('organization_detail.json')),
    );
    on('GET /public/doctors', (_) => jsonResponse(fixture('doctors.json')));
    on(
      'GET /public/doctors/$doctorId',
      (_) => jsonResponse(fixture('doctor_detail.json')),
    );
    on(
      'GET /public/doctors/$doctorId/slots',
      (_) => jsonResponse(fixture('slots.json')),
    );
    on(
      'GET /public/doctors/$doctorId/token-window',
      (_) => jsonResponse(fixture('token_window.json')),
    );
    on('GET /me', (_) => jsonResponse(meJson()));
    on('GET /orgs', (_) => jsonResponse(myOrgsJson()));
    on(
      'GET /orgs/$orgId/appointments',
      (_) => jsonResponse({
        'data': [appointmentRow()],
      }),
    );
    on(
      'GET /orgs/$orgId/appointments/appt-1',
      (_) => jsonResponse(appointmentRow()),
    );
    on('GET /patient/token-status', (_) => jsonResponse(tokenStatusJson()));
  }
}

class FakeGoogle implements GoogleAuthGateway {
  FakeGoogle({this.idToken = 'google-id-token', this.cancel = false});

  final String idToken;
  final bool cancel;
  int signOuts = 0;

  @override
  Future<String> obtainIdToken() async {
    if (cancel) throw const GoogleSignInCancelled();
    return idToken;
  }

  @override
  Future<void> signOut() async => signOuts++;
}
