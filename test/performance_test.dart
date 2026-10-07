import 'dart:async';
import 'dart:convert';

import 'package:clinic_app/core/auth/auth_controller.dart';
import 'package:clinic_app/core/network/api_client.dart';
import 'package:clinic_app/core/network/memo_cache.dart';
import 'package:clinic_app/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  group('MemoCache', () {
    test('serves repeats from memory and shares in-flight loads', () async {
      final cache = MemoCache<int>(ttl: const Duration(minutes: 1));
      var loads = 0;
      final gate = Completer<int>();
      Future<int> load() {
        loads++;
        return gate.future;
      }

      final a = cache.get('k', load);
      final b = cache.get('k', load);
      gate.complete(7);
      expect(await a, 7);
      expect(await b, 7);
      expect(await cache.get('k', load), 7);
      expect(loads, 1);

      await cache.get('k', () async => 8, refresh: true);
      expect(await cache.get('k', load), 8);
    });

    test('never caches failures', () async {
      final cache = MemoCache<int>(ttl: const Duration(minutes: 1));
      await expectLater(
        cache.get('k', () async => throw StateError('offline')),
        throwsStateError,
      );
      expect(await cache.get('k', () async => 3), 3);
    });
  });

  group('fast startup', () {
    const session = SessionTokens(accessToken: 'a', refreshToken: 'r');

    test(
      'returning user opens from cache before the network answers',
      () async {
        final storage = InMemoryTokenStorage(session)
          ..cachedUser = jsonEncode(meJson());
        final backend = FakeBackend()
          ..on('GET /me', (_) => jsonResponse(meJson()));
        final api = ApiClient(
          storage: storage,
          httpClient: backend.client,
          baseUrl: 'https://x.test/api',
        );
        final auth = AuthController(
          api: api,
          storage: storage,
          google: FakeGoogle(),
        );
        await auth.restore();
        expect(auth.status, AuthStatus.authenticated);
        expect(auth.user?.firstName, 'Asha');
      },
    );

    test('a session revoked server-side still ends at login', () async {
      final storage = InMemoryTokenStorage(session)
        ..cachedUser = jsonEncode(meJson());
      final backend = FakeBackend()
        ..on(
          'GET /me',
          (_) => jsonResponse({
            'error': {'code': 'TOKEN_EXPIRED', 'message': ''},
          }, 401),
        )
        ..on(
          'POST /auth/refresh',
          (_) => jsonResponse({
            'error': {'code': 'REFRESH_REUSE_DETECTED', 'message': ''},
          }, 401),
        );
      final auth = AuthController(
        api: ApiClient(
          storage: storage,
          httpClient: backend.client,
          baseUrl: 'https://x.test/api',
        ),
        storage: storage,
        google: FakeGoogle(),
      );
      await auth.restore(minimumSplash: const Duration(milliseconds: 200));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(auth.status, AuthStatus.unauthenticated);
      expect(storage.tokens, isNull);
    });
  });
}
