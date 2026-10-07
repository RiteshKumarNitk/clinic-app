/// Tolerant readers for backend JSON. Optional fields the backend may omit or
/// null never crash a screen; required identifiers do.
typedef Json = Map<String, dynamic>;

String? str(Json j, String key) {
  final v = j[key];
  if (v is String && v.trim().isNotEmpty) return v;
  return null;
}

String reqStr(Json j, String key) {
  final v = j[key];
  if (v is String && v.isNotEmpty) return v;
  throw FormatException('Missing "$key"');
}

int? intOrNull(Json j, String key) {
  final v = j[key];
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? doubleOrNull(Json j, String key) {
  final v = j[key];
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool boolOr(Json j, String key, bool fallback) {
  final v = j[key];
  return v is bool ? v : fallback;
}

DateTime? date(Json j, String key) {
  final v = j[key];
  return v is String ? DateTime.tryParse(v)?.toUtc() : null;
}

Json? obj(Json j, String key) {
  final v = j[key];
  return v is Map<String, dynamic> ? v : null;
}

List<Json> objList(Json j, String key) {
  final v = j[key];
  return v is List ? v.whereType<Json>().toList(growable: false) : const [];
}

List<String> strList(Json j, String key) {
  final v = j[key];
  return v is List
      ? v.whereType<String>().where((s) => s.trim().isNotEmpty).toList()
      : const [];
}
