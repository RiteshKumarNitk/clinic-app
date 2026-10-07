import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../errors/api_exception.dart';
import '../storage/token_storage.dart';

typedef JsonMap = Map<String, dynamic>;

enum _Refresh { rotated, rejected, offline }

/// Whether a request carries the session.
enum Auth { none, required }

/// The single HTTP gateway of the app. Screens never build URLs — they call
/// repositories, which call this.
///
/// Responsibilities:
///  * `X-Client: app`, so the backend answers with bearer tokens rather than a
///    web cookie;
///  * the auth interceptor: attaches `Authorization: Bearer …` and, on a 401,
///    performs one single-flight refresh and replays the request;
///  * converting every failure into an [ApiException].
class ApiClient {
  ApiClient({
    required this.storage,
    http.Client? httpClient,
    String? baseUrl,
    Duration? timeout,
  }) : _http = httpClient ?? http.Client(),
       _baseUrl = _trimSlash(baseUrl ?? AppConfig.apiBaseUrl),
       _timeout = timeout ?? AppConfig.requestTimeout;

  final TokenStorage storage;
  final http.Client _http;
  final String _baseUrl;
  final Duration _timeout;

  /// Called once when the refresh token is rejected — the auth controller
  /// listens and moves the app to signed-out.
  void Function()? onSessionExpired;

  Future<_Refresh>? _refreshing;

  Future<JsonMap> get(
    String path, {
    Map<String, String>? query,
    Auth auth = Auth.none,
  }) async => _asMap(await _send('GET', path, query: query, auth: auth));

  Future<JsonMap> post(
    String path, {
    JsonMap? body,
    Auth auth = Auth.required,
  }) async => _asMap(await _send('POST', path, body: body, auth: auth));

  Future<JsonMap> delete(
    String path, {
    JsonMap? body,
    Auth auth = Auth.required,
  }) async => _asMap(await _send('DELETE', path, body: body, auth: auth));

  /// `{ data: [...] }` collections.
  Future<List<JsonMap>> getList(
    String path, {
    Map<String, String>? query,
    Auth auth = Auth.none,
  }) async {
    final map = await get(path, query: query, auth: auth);
    final data = map['data'];
    if (data is List) return data.whereType<JsonMap>().toList(growable: false);
    throw const ApiException(
      code: 'MALFORMED',
      message: 'Unexpected response.',
    );
  }

  /// Exchanges a Google ID token for a platform session. Unauthenticated by
  /// definition, and never retried through refresh.
  Future<SessionTokens> verifyGoogle(String idToken) async {
    final decoded = await _send(
      'POST',
      '/auth/google/verify',
      body: {'idToken': idToken},
      auth: Auth.none,
    );
    final tokens = SessionTokens.fromJson(decoded);
    if (tokens == null) {
      throw const ApiException(
        code: 'MALFORMED',
        message: 'No session issued.',
      );
    }
    return tokens;
  }

  /// Best-effort server-side revoke of the refresh token.
  Future<void> logout() async {
    final tokens = await storage.read();
    if (tokens == null) return;
    try {
      await _send(
        'POST',
        '/auth/logout',
        body: {'refreshToken': tokens.refreshToken},
        auth: Auth.none,
        allowRefresh: false,
      );
    } catch (_) {
      // Local sign-out proceeds regardless.
    }
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    required Auth auth,
    bool allowRefresh = true,
  }) async {
    final tokens = auth == Auth.required ? await storage.read() : null;
    if (auth == Auth.required && tokens == null) {
      throw const ApiException(
        code: 'NOT_AUTHENTICATED',
        message: 'Not signed in.',
        status: 401,
      );
    }

    final response = await _raw(method, path, query, body, tokens?.accessToken);
    final decoded = _decode(response);
    final status = response.statusCode;
    if (status >= 200 && status < 300) return decoded;

    if (status == 401 && auth == Auth.required && allowRefresh) {
      switch (await _refresh()) {
        case _Refresh.rotated:
          return _send(
            method,
            path,
            query: query,
            body: body,
            auth: auth,
            allowRefresh: false,
          );
        case _Refresh.offline:
          throw const ApiException(code: 'NETWORK', message: 'Refresh failed.');
        case _Refresh.rejected:
          onSessionExpired?.call();
      }
    }
    throw _error(status, decoded);
  }

  Future<http.Response> _raw(
    String method,
    String path,
    Map<String, String>? query,
    Object? body,
    String? accessToken,
  ) async {
    final uri = _uri(path, query);
    final request = http.Request(method, uri)
      ..headers.addAll({
        'X-Client': 'app',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        if (body != null) 'Content-Type': 'application/json',
      });
    if (body != null) request.body = jsonEncode(body);
    try {
      final streamed = await _http.send(request).timeout(_timeout);
      return await http.Response.fromStream(streamed).timeout(_timeout);
    } on TimeoutException {
      throw const ApiException(code: 'TIMEOUT', message: 'Request timed out.');
    } on SocketException {
      throw const ApiException(
        code: 'NETWORK',
        message: 'Network unreachable.',
      );
    } on http.ClientException {
      throw const ApiException(code: 'NETWORK', message: 'Network error.');
    }
  }

  /// One refresh at a time: refresh tokens are single-use server-side, so two
  /// concurrent rotations would revoke the session.
  Future<_Refresh> _refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<_Refresh> _doRefresh() async {
    final tokens = await storage.read();
    if (tokens == null) return _Refresh.rejected;
    final http.Response response;
    try {
      response = await _raw('POST', '/auth/refresh', null, {
        'refreshToken': tokens.refreshToken,
      }, null);
    } on ApiException {
      // Offline: keep the stored session — only the server may end it.
      return _Refresh.offline;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final rotated = SessionTokens.fromJson(_decode(response));
      if (rotated != null) {
        await storage.write(rotated);
        return _Refresh.rotated;
      }
    }
    if (response.statusCode >= 500) return _Refresh.offline;
    await storage.clear();
    return _Refresh.rejected;
  }

  Uri _uri(String path, Map<String, String>? query) {
    final normalized = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseUrl$normalized');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  static Object? _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  static ApiException _error(int status, Object? decoded) {
    if (decoded is Map && decoded['error'] is Map) {
      final e = decoded['error'] as Map;
      return ApiException(
        code: e['code'] is String ? e['code'] as String : 'HTTP_$status',
        message: e['message'] is String ? e['message'] as String : '',
        status: status,
        details: e['details'],
      );
    }
    return ApiException(code: 'HTTP_$status', message: '', status: status);
  }

  static JsonMap _asMap(Object? decoded) {
    if (decoded is JsonMap) return decoded;
    throw const ApiException(
      code: 'MALFORMED',
      message: 'Unexpected response.',
    );
  }

  static String _trimSlash(String v) =>
      v.endsWith('/') ? v.substring(0, v.length - 1) : v;
}
