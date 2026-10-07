import 'dart:async';
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

  /// Browsing without an account: discovery works, anything personal
  /// (booking, appointments, queue) asks for Google sign-in first. Never
  /// persisted — the next launch shows the login screen again.
  guest,
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
  bool _expiredDuringRestore = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isGuest => _status == AuthStatus.guest;

  /// True while the Google → platform exchange is running.
  bool get busy => _busy;

  /// Splash: decide between "signed in" and "show Continue with Google".
  ///
  /// A stored session is validated with `GET /me` (the API client refreshes an
  /// expired access token on the way). If the network is down, a stored
  /// session plus the cached profile still opens the app — only a server
  /// rejection signs the patient out.
  ///
  /// [minimumSplash] keeps the branded splash up for at least that long, so it
  /// never flashes by on a fast device.
  Future<void> restore({Duration minimumSplash = Duration.zero}) async {
    final started = DateTime.now();
    final next = await _restoredStatus();
    final remaining = minimumSplash - DateTime.now().difference(started);
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
    if (_expiredDuringRestore) {
      _user = null;
      await _storage.clear();
      return _set(AuthStatus.unauthenticated);
    }
    _set(next);
  }

  Future<AuthStatus> _restoredStatus() async {
    final tokens = await _storage.read();
    if (tokens == null) return AuthStatus.unauthenticated;

    // Returning user: open instantly from the cached profile and confirm the
    // session in the background. A rejected session still signs them out
    // (the API client reports it via onSessionExpired).
    final cached = await _storage.readCachedUser();
    if (cached != null) {
      try {
        _user = AppUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
        unawaited(_revalidate());
        return AuthStatus.authenticated;
      } catch (_) {
        // Unreadable cache — fall through to a normal network check.
      }
    }

    try {
      await _loadMe();
      return AuthStatus.authenticated;
    } on ApiException catch (e) {
      if (e.isUnauthenticated) {
        await _storage.clear();
        _user = null;
        return AuthStatus.unauthenticated;
      }
      final cached = await _storage.readCachedUser();
      if (cached != null) {
        _user = AppUser.fromJson(jsonDecode(cached) as Map<String, dynamic>);
      }
      // Session exists but no network: still signed in; screens show their
      // own offline states.
      return AuthStatus.authenticated;
    }
  }

  Future<void> _revalidate() async {
    try {
      await _loadMe();
      notifyListeners();
    } on ApiException catch (e) {
      if (e.isUnauthenticated) _expire();
    } catch (_) {
      // Offline — keep the cached session.
    }
  }

  /// "Continue as guest" on the login screen.
  void continueAsGuest() => _set(AuthStatus.guest);

  /// Leave guest mode and return to the login screen.
  void exitGuest() => _set(AuthStatus.unauthenticated);

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
    // Rejected while the splash is still up: restore() applies it.
    if (_status == AuthStatus.unknown) {
      _expiredDuringRestore = true;
      return;
    }
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
