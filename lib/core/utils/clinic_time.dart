import 'package:intl/intl.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Times are always shown in the *clinic's* timezone (the backend sends UTC
/// instants plus an IANA zone), so a patient travelling — or a phone with a
/// wrong zone — still sees the time printed on the clinic's door.
class ClinicTime {
  ClinicTime._();

  static bool _ready = false;

  static void ensureInitialized() {
    if (_ready) return;
    tzdata.initializeTimeZones();
    _ready = true;
  }

  static tz.Location _loc(String? zone) {
    ensureInitialized();
    if (zone == null || zone.isEmpty) return tz.local;
    try {
      return tz.getLocation(zone);
    } catch (_) {
      return tz.local;
    }
  }

  /// [instant] converted to wall-clock time at the clinic.
  static tz.TZDateTime local(DateTime instant, String? zone) =>
      tz.TZDateTime.from(instant, _loc(zone));

  /// Today's calendar day at the clinic.
  static DateTime today(String? zone, {DateTime? now}) {
    final t = local(now ?? DateTime.now(), zone);
    return DateTime(t.year, t.month, t.day);
  }

  static String time(DateTime instant, String? zone) =>
      DateFormat('h:mm a').format(local(instant, zone));

  static String date(DateTime instant, String? zone) =>
      DateFormat('EEE, d MMM yyyy').format(local(instant, zone));

  static String shortDate(DateTime instant, String? zone) =>
      DateFormat('EEE, d MMM').format(local(instant, zone));

  /// `YYYY-MM-DD` for a calendar day — the format the slots API takes.
  static String apiDate(DateTime day) => DateFormat('yyyy-MM-dd').format(day);
}

/// Consultation fees arrive in minor units (paise).
String? formatFee(int? minor) {
  if (minor == null) return null;
  final rupees = minor / 100;
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: rupees == rupees.roundToDouble() ? 0 : 2,
  ).format(rupees);
}
