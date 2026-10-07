import 'package:geolocator/geolocator.dart';

/// Why "near me" couldn't get a position, in words a patient understands.
class LocationUnavailable implements Exception {
  const LocationUnavailable(this.message, {this.canOpenSettings = false});

  final String message;
  final bool canOpenSettings;
}

/// Approximate position for "clinics near me". Asked only when the patient
/// taps Near me, never in the background; low accuracy is plenty for ranking.
class DeviceLocation {
  DeviceLocation._();

  static Future<({double lat, double lng})> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable(
        'Turn on location to see clinics near you.',
        canOpenSettings: true,
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationUnavailable(
        'Allow location access to see clinics near you.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationUnavailable(
        'Location is blocked for CityCare. Enable it in Settings.',
        canOpenSettings: true,
      );
    }
    final last = await Geolocator.getLastKnownPosition();
    final pos =
        last ??
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 12),
          ),
        );
    return (lat: pos.latitude, lng: pos.longitude);
  }

  static Future<void> openSettings() async {
    if (!await Geolocator.openLocationSettings()) {
      await Geolocator.openAppSettings();
    }
  }
}
