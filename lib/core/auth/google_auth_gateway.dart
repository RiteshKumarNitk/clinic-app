import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';

/// Thrown when the user closes the Google account picker.
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}

/// The only place that talks to the Google Sign-In SDK. Abstract so the auth
/// controller can be tested without a device.
abstract class GoogleAuthGateway {
  /// Shows the account picker and returns a Google ID token whose audience is
  /// the backend's web client ID.
  Future<String> obtainIdToken();

  Future<void> signOut();
}

class GoogleSignInGateway implements GoogleAuthGateway {
  GoogleSignInGateway([GoogleSignIn? google])
    : _google =
          google ??
          GoogleSignIn(
            scopes: const ['email', 'profile'],
            serverClientId: AppConfig.googleServerClientId,
          );

  final GoogleSignIn _google;

  @override
  Future<String> obtainIdToken() async {
    // Always show the picker so "switch account" after logout works.
    await _google.signOut().catchError((_) => null);
    final account = await _google.signIn();
    if (account == null) throw const GoogleSignInCancelled();
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google did not return an ID token.');
    }
    return idToken;
  }

  @override
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Google-side sign-out is cosmetic; the platform session is what counts.
    }
  }
}
