// Production smoke test — hits the live backend through the app's own
// repositories. Excluded from the default run; execute with:
//
//   flutter test test/smoke --dart-define=SMOKE=true
//
// Authenticated steps (appointments, queue) additionally need a real platform
// session obtained through Google sign-in on a device:
//
//   --dart-define=SMOKE_ACCESS_TOKEN=... --dart-define=SMOKE_REFRESH_TOKEN=...
//
// Read-only: this test never books or cancels anything.
@Tags(['smoke'])
@Timeout(Duration(minutes: 3))
library;

import 'package:clinic_app/core/network/api_client.dart';
import 'package:clinic_app/core/storage/token_storage.dart';
import 'package:clinic_app/core/utils/clinic_time.dart';
import 'package:clinic_app/features/appointments/data/appointment_repository.dart';
import 'package:clinic_app/features/clinics/data/clinic_repository.dart';
import 'package:clinic_app/features/doctors/data/doctor_models.dart';
import 'package:clinic_app/features/doctors/data/doctor_repository.dart';
import 'package:clinic_app/features/queue/data/queue_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const _enabled = bool.fromEnvironment('SMOKE');
const _access = String.fromEnvironment('SMOKE_ACCESS_TOKEN');
const _refresh = String.fromEnvironment('SMOKE_REFRESH_TOKEN');

void main() {
  final storage = InMemoryTokenStorage(
    _access.isEmpty
        ? null
        : const SessionTokens(accessToken: _access, refreshToken: _refresh),
  );
  final api = ApiClient(storage: storage);
  final clinics = ClinicRepository(api);
  final doctors = DoctorRepository(api);
  final appointments = AppointmentRepository(api, clinics);
  final queue = QueueRepository(api);

  setUpAll(ClinicTime.ensureInitialized);

  test(
    'discovery → clinic → doctor → types → availability → token window',
    () async {
      final page = await clinics.list();
      // ignore: avoid_print
      print('clinics: total=${page.total}');
      expect(page.items, isNotEmpty);

      final summary = page.items.first;
      final clinic = await clinics.detail(summary.slug);
      expect(clinic.id, summary.id);
      // ignore: avoid_print
      print(
        'clinic: ${clinic.name} (${clinic.id}) doctors=${clinic.doctors.length} '
        'types=${clinic.appointmentTypes.map((t) => '${t.name}/${t.durationMinutes}m').join(', ')}',
      );
      expect(clinic.doctors, isNotEmpty);

      final doctor = await doctors.detail(clinic.doctors.first.id);
      expect(doctor.clinic.ref.id, clinic.id);
      // ignore: avoid_print
      print('doctor: ${doctor.displayName} mode=${doctor.bookingMode.name}');

      final searched = await doctors.list(query: doctor.displayName);
      expect(searched.items.map((d) => d.id), contains(doctor.id));

      if (doctor.bookingMode.offersSlots) {
        final typeId = doctor.clinic.appointmentTypes.firstOrNull?.id;
        var found = 0;
        var day = ClinicTime.today('Asia/Kolkata');
        for (var i = 0; i < 14 && found == 0; i++) {
          final slots = await appointments.slots(
            doctorId: doctor.id,
            day: day,
            appointmentTypeId: typeId,
          );
          found = slots.slots.length;
          if (found > 0) {
            // ignore: avoid_print
            print(
              'availability: ${ClinicTime.apiDate(day)} → $found slots, first '
              '${ClinicTime.time(slots.slots.first.start, slots.timezone)} ${slots.timezone}',
            );
          }
          day = day.add(const Duration(days: 1));
        }
        expect(found, greaterThan(0), reason: 'no slots in the next 14 days');
      }

      if (doctor.bookingMode.offersTokens) {
        final w = await doctors.tokenWindow(doctor.id);
        // ignore: avoid_print
        print(
          'token window: ${w.status} bookable=${w.bookable} '
          '${w.opensAt}-${w.closesAt} queue@${w.queueStartAt}',
        );
        expect(w.date, isNotEmpty);
      }
    },
    skip: !_enabled,
  );

  test(
    'authenticated: platform token → /me, appointments, queue',
    () async {
      final me = await api.get('/me', auth: Auth.required);
      // ignore: avoid_print
      print('me: ${me['email']}');
      final mine = await appointments.myAppointments();
      // ignore: avoid_print
      print('appointments: ${mine.length}');
      for (final a in mine.where((a) => a.hasQueue).take(1)) {
        final s = await queue.status(a.id);
        // ignore: avoid_print
        print('queue: #${s.tokenNumber} ${s.state} ahead=${s.ahead}');
      }
    },
    skip: !_enabled || _access.isEmpty
        ? 'needs SMOKE_ACCESS_TOKEN from a real Google sign-in'
        : false,
  );
}
