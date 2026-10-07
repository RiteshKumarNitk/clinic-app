import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The platform session issued by `POST /api/auth/google/verify` (and rotated
/// by `/api/auth/refresh`).
class SessionTokens {
  const SessionTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  static SessionTokens? fromJson(Object? json) {
    if (json is! Map) return null;
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    if (access is! String || access.isEmpty) return null;
    if (refresh is! String || refresh.isEmpty) return null;
    return SessionTokens(accessToken: access, refreshToken: refresh);
  }

  Map<String, String> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
  };
}

/// Where the session lives between launches. Abstract so tests can use the
/// in-memory version.
abstract class TokenStorage {
  Future<SessionTokens?> read();
  Future<void> write(SessionTokens tokens);
  Future<void> clear();

  /// The last successfully loaded profile, so a cold start without network
  /// still opens the app for a signed-in patient.
  Future<String?> readCachedUser();
  Future<void> writeCachedUser(String json);
}

/// Keychain / EncryptedSharedPreferences backed storage.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'clinic.session.v1';
  static const _userKey = 'clinic.user.v1';

  final FlutterSecureStorage _storage;
  SessionTokens? _memo;

  @override
  Future<SessionTokens?> read() async {
    if (_memo != null) return _memo;
    try {
      final raw = await _storage.read(key: _sessionKey);
      if (raw == null) return null;
      return _memo = SessionTokens.fromJson(jsonDecode(raw));
    } catch (_) {
      // Corrupt or undecryptable (e.g. restored backup) — treat as signed out.
      return null;
    }
  }

  @override
  Future<void> write(SessionTokens tokens) async {
    _memo = tokens;
    await _storage.write(key: _sessionKey, value: jsonEncode(tokens.toJson()));
  }

  @override
  Future<void> clear() async {
    _memo = null;
    await _storage.delete(key: _sessionKey);
    await _storage.delete(key: _userKey);
  }

  @override
  Future<String?> readCachedUser() async {
    try {
      return await _storage.read(key: _userKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> writeCachedUser(String json) =>
      _storage.write(key: _userKey, value: json);
}

/// Test double.
class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this.tokens]);

  SessionTokens? tokens;
  String? cachedUser;

  @override
  Future<SessionTokens?> read() async => tokens;

  @override
  Future<void> write(SessionTokens value) async => tokens = value;

  @override
  Future<void> clear() async {
    tokens = null;
    cachedUser = null;
  }

  @override
  Future<String?> readCachedUser() async => cachedUser;

  @override
  Future<void> writeCachedUser(String json) async => cachedUser = json;
}
