/// Build-time configuration for the Clinic App.
///
/// Every value can be overridden with `--dart-define`, so a staging or local
/// backend never needs a code change. Nothing here is a secret: the Google
/// value is an OAuth *client ID* (public by design) — client secrets, database
/// URLs and server keys live only on the backend.
class AppConfig {
  AppConfig._();

  /// Platform API root, without a trailing slash.
  static const String apiBaseUrl = String.fromEnvironment(
    'CLINIC_API_BASE_URL',
    defaultValue: 'https://remind-me-indol.vercel.app/api',
  );

  /// The OAuth *web* client ID the backend accepts as the ID-token audience
  /// (`POST /api/auth/google/verify`). Google Sign-In mints the ID token for
  /// this audience when it is passed as `serverClientId`.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '883368917967-1lcbvobp9pinb009ijtc4cb75hkeobe3.apps.googleusercontent.com',
  );

  static const Duration requestTimeout = Duration(seconds: 20);

  /// How often the live queue screen re-reads the server.
  static const Duration queuePollInterval = Duration(seconds: 15);
}
