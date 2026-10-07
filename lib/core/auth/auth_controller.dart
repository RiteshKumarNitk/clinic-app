import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../errors/api_exception.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';
import 'app_user.dart';
import 'google_auth_gateway.dart';

enum AuthStatus {
  /// Restoring a stored session — the router keeps the splash up.
  unknown,
  authenticated,
  unauthenticated,
}

/// The one authentication state of the Clinic App. The router, every screen
/// and the API client read it; nothing else holds a login.
class AuthController extends ChangeNotifier {
  AuthController({
    required ApiClient api,
    required TokenStorage storage,
    required GoogleAuthGateway google,
  }) : _api = api,
       _storage = storage,
       _google = google {
    _api.onSessionExpired = _expire;
  }

  final ApiClient _api;
  final TokenStorage _storage;
  final GoogleAuthGateway _google;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  bool _busy = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// True while the Google → platform exchange is running.
  bool get busy => _busy;

  /// Splash: decide between "signed in" and "show Continue with Google".
  ///
  /// A stored session is validated with `GET /me` (the API client refreshes an
  /// expired access token on the way). If the network is down, a stored
  /// session plus the cached profile still opens the app — only a server
  /// rejection signs the patient out.
  Future<void> restore() async {
    final tokens = await _storage.read();
    if (tokens == null) return _set(AuthStatus.unauthenticated);

    try {
      await _loadMe();
      _set(AuthStatus.authenticated);
    } on ApiException catch (e) {
      if (e.isUnauthenticated) {
        await _storage.clear();
        _user = null;
        return _set(AuthStatus.unauthenticated);
      }
      final cached = await _storage.readCachedUser();
      if (cached != null) {
        _user = AppUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        return _set(AuthStatus.authenticated);
      }
      // Session exists but nothing to show and no network: still treat as
      // signed in; screens show their own offline states.
      _set(AuthStatus.authenticated);
    }
  }

  /// Continue with Google → ID token → `POST /auth/google/verify` → session.
  /// Returns normally on success; throws [GoogleSignInCancelled] if the user
  /// backed out, or another error to be shown by the login screen.
  Future<void> signInWithGoogle() async {
    if (_busy) return;
    _busy = true;
    notifyListeners();
    try {
      final idToken = await _google.obtainIdToken();
      final tokens = await _api.verifyGoogle(idToken);
      await _storage.write(tokens);
      await _loadMe();
      _set(AuthStatus.authenticated);
    } catch (e) {
      if (e is! GoogleSignInCancelled) {
        developer.log('Google sign-in failed', name: 'Auth', error: e);
      }
      await _storage.clear();
      rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshProfile() async {
    try {
      await _loadMe();
      notifyListeners();
    } catch (_) {}
  }

  /// Revoke server-side, forget locally, sign out of Google.
  Future<void> logout() async {
    await _api.logout();
    await _storage.clear();
    await _google.signOut();
    _user = null;
    _set(AuthStatus.unauthenticated);
  }

  Future<void> _loadMe() async {
    final json = await _api.get('/me', auth: Auth.required);
    _user = AppUser.fromJson(json);
    await _storage.writeCachedUser(jsonEncode(_user!.toJson()));
  }

  void _expire() {
    if (_status != AuthStatus.authenticated) return;
    _user = null;
    _storage.clear();
    _set(AuthStatus.unauthenticated);
  }

  void _set(AuthStatus status) {
    _status = status;
    notifyListeners();
  }
}
