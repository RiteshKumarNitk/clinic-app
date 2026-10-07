import 'dart:convert';

import 'package:clinic_app/core/auth/auth_controller.dart';
import 'package:clinic_app/core/auth/google_auth_gateway.dart';
import 'package:clinic_app/core/errors/api_exception.dart';
import 'package:clinic_app/core/network/api_client.dart';
import 'package:clinic_app/core/storage/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'support.dart';

const _session = SessionTokens(accessToken: 'acc-1', refreshToken: 'ref-1');

void main() {
  group('ApiClient auth interceptor', () {
    test('attaches Bearer + X-Client: app on protected calls', () async {
      final backend = FakeBackend()..serveEverything();
      final api = ApiClient(
        storage: InMemoryTokenStorage(_session),
        httpClient: backend.client,
        baseUrl: 'https://x.test/api',
      );
      await api.get('/me', auth: Auth.required);
      final req = backend.requests.single;
      expect(req.headers['Authorization'], 'Bearer acc-1');
      expect(req.headers['X-Client'], 'app');
    });

    test('public calls never send the token', () async {
      final backend = FakeBackend()..serveEverything();
      final api = ApiClient(
        storage: InMemoryTokenStorage(_session),
        httpClient: backend.client,
        baseUrl: 'https://x.test/api',
      );
      await api.get('/public/organizations');
      expect(backend.requests.single.headers['Authorization'], isNull);
    });

    test('expired access token → one refresh → replay succeeds', () async {
      final storage = InMemoryTokenStorage(_session);
      var meCalls = 0;
      final backend = FakeBackend()
        ..on('GET /me', (req) {
          meCalls++;
          return req.headers['Authorization'] == 'Bearer acc-2'
              ? jsonResponse(meJson())
              : jsonResponse({
                  'error': {'code': 'TOKEN_EXPIRED', 'message': 'expired'},
                }, 401);
        })
        ..on('POST /auth/refresh', (req) {
          expect(jsonDecode(req.body), {'refreshToken': 'ref-1'});
          return jsonResponse({
            'accessToken': 'acc-2',
            'refreshToken': 'ref-2',
          });
        });
      final api = ApiClient(
        storage: storage,
        httpClient: backend.client,
        baseUrl: 'https://x.test/api',
      );
      final me = await api.get('/me', auth: Auth.required);
      expect(me['email'], 'asha@example.com');
      expect(meCalls, 2);
      expect(storage.tokens?.refreshToken, 'ref-2');
    });

    test('concurrent 401s share a single refresh', () async {
      var refreshes = 0;
      final backend = FakeBackend()
        ..on(
          'GET /me',
          (req) => req.headers['Authorization'] == 'Bearer acc-2'
              ? jsonResponse(meJson())
              : jsonResponse({
                  'error': {'code': 'TOKEN_EXPIRED', 'message': ''},
                }, 401),
        )
        ..on('POST /auth/refresh', (_) {
          refreshes++;
          return jsonResponse({
            'accessToken': 'acc-2',
            'refreshToken': 'ref-2',
          });
        });
      final api = ApiClient(
        storage: InMemoryTokenStorage(_session),
        httpClient: backend.client,
        baseUrl: 'https://x.test/api',
      );
      await Future.wait([
        api.get('/me', auth: Auth.required),
        api.get('/me', auth: Auth.required),
      ]);
      expect(refreshes, 1);
    });

    test('rejected refresh clears the session and reports expiry', () async {
      final storage = InMemoryTokenStorage(_session);
      var expired = false;
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
            'error': {'code': 'NOT_AUTHENTICATED', 'message': ''},
          }, 401),
        );
      final api = ApiClient(
        storage: storage,
        httpClient: backend.client,
        baseUrl: 'https://x.test/api',
      )..onSessionExpired = () => expired = true;
      await expectLater(
        api.get('/me', auth: Auth.required),
        throwsA(
          isA<ApiException>().having(
            (e) => e.isUnauthenticated,
            'unauth',
            true,
          ),
        ),
      );
      expect(expired, isTrue);
      expect(storage.tokens, isNull);
    });

    test('offline during refresh keeps the session', () async {
      final storage = InMemoryTokenStorage(_session);
      var expired = false;
      final client = MockClient((req) async {
        if (req.url.path.endsWith('/auth/refresh')) {
          throw http.ClientException('offline');
        }
        return jsonResponse({
          'error': {'code': 'TOKEN_EXPIRED', 'message': ''},
        }, 401);
      });
      final api = ApiClient(
        storage: storage,
        httpClient: client,
        baseUrl: 'https://x.test/api',
      )..onSessionExpired = () => expired = true;
      await expectLater(
        api.get('/me', auth: Auth.required),
        throwsA(
          isA<ApiException>().having((e) => e.isNetwork, 'network', true),
        ),
      );
      expect(expired, isFalse);
      expect(storage.tokens, isNotNull);
    });

    test('error envelope is mapped and never shown raw', () async {
      final backend = FakeBackend()
        ..on(
          'POST /patient/appointments',
          (_) => jsonResponse({
            'error': {
              'code': 'APPOINTMENT_SLOT_TAKEN',
              'message': 'Prisma P2002 ...',
            },
          }, 409),
        );
      final api = ApiClient(
        storage: InMemoryTokenStorage(_session),
        httpClient: backend.client,
        baseUrl: 'https://x.test/api',
      );
      try {
        await api.post('/patient/appointments', body: {});
        fail('should throw');
      } on ApiException catch (e) {
        expect(e.code, 'APPOINTMENT_SLOT_TAKEN');
        expect(isSlotConflict(e), isTrue);
        final msg = friendlyMessage(e, fallback: 'x');
        expect(msg, contains('no longer available'));
        expect(msg, isNot(contains('Prisma')));
      }
      expect(
        friendlyMessage(
          const ApiException(
            code: 'INTERNAL',
            message: 'Null check operator',
            status: 500,
          ),
          fallback: "We couldn't load clinics.",
        ),
        "We couldn't load clinics.",
      );
    });
  });

  group('AuthController — one session for the whole app', () {
    AuthController make(
      FakeBackend backend,
      InMemoryTokenStorage storage,
      FakeGoogle google,
    ) => AuthController(
      api: ApiClient(
        storage: storage,
        httpClient: backend.client,
        baseUrl: 'https://x.test/api',
      ),
      storage: storage,
      google: google,
    );

    test('fresh install: no session → unauthenticated (login)', () async {
      final auth = make(FakeBackend(), InMemoryTokenStorage(), FakeGoogle());
      expect(auth.status, AuthStatus.unknown);
      await auth.restore();
      expect(auth.status, AuthStatus.unauthenticated);
    });

    test(
      'Continue with Google → verify → platform session → authenticated',
      () async {
        final storage = InMemoryTokenStorage();
        final backend = FakeBackend()
          ..serveEverything()
          ..on('POST /auth/google/verify', (req) {
            expect(jsonDecode(req.body), {'idToken': 'google-id-token'});
            expect(req.headers['X-Client'], 'app');
            return jsonResponse({
              'accessToken': 'acc-1',
              'refreshToken': 'ref-1',
              'tokenType': 'Bearer',
            });
          });
        final auth = make(backend, storage, FakeGoogle());
        await auth.signInWithGoogle();
        expect(auth.status, AuthStatus.authenticated);
        expect(auth.user?.email, 'asha@example.com');
        expect(storage.tokens?.accessToken, 'acc-1');
        // The platform token — not a Google/Firebase token — authorises /me.
        final me = backend.requests.firstWhere(
          (r) => r.url.path.endsWith('/me'),
        );
        expect(me.headers['Authorization'], 'Bearer acc-1');
      },
    );

    test('cancelled picker leaves the user signed out', () async {
      final auth = make(
        FakeBackend(),
        InMemoryTokenStorage(),
        FakeGoogle(cancel: true),
      );
      await auth.restore();
      await expectLater(
        auth.signInWithGoogle(),
        throwsA(isA<GoogleSignInCancelled>()),
      );
      expect(auth.status, AuthStatus.unauthenticated);
      expect(auth.busy, isFalse);
    });

    test('app restart restores the stored session without Google', () async {
      final google = FakeGoogle();
      final auth = make(
        FakeBackend()..serveEverything(),
        InMemoryTokenStorage(_session),
        google,
      );
      await auth.restore();
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.user?.fullName, 'Asha Verma');
    });

    test('restart while offline still opens the app from cache', () async {
      final storage = InMemoryTokenStorage(_session)
        ..cachedUser = jsonEncode(meJson());
      final offline = MockClient(
        (_) async => throw http.ClientException('offline'),
      );
      final auth = AuthController(
        api: ApiClient(
          storage: storage,
          httpClient: offline,
          baseUrl: 'https://x.test/api',
        ),
        storage: storage,
        google: FakeGoogle(),
      );
      await auth.restore();
      expect(auth.status, AuthStatus.authenticated);
      expect(auth.user?.firstName, 'Asha');
    });

    test('revoked session on restart → login', () async {
      final storage = InMemoryTokenStorage(_session);
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
      final auth = make(backend, storage, FakeGoogle());
      await auth.restore();
      expect(auth.status, AuthStatus.unauthenticated);
      expect(storage.tokens, isNull);
    });

    test(
      'logout revokes server-side, clears storage, signs out of Google',
      () async {
        final storage = InMemoryTokenStorage(_session);
        final google = FakeGoogle();
        final backend = FakeBackend()
          ..serveEverything()
          ..on('POST /auth/logout', (req) {
            expect(jsonDecode(req.body), {'refreshToken': 'ref-1'});
            return jsonResponse({'ok': true});
          });
        final auth = make(backend, storage, google);
        await auth.restore();
        await auth.logout();
        expect(auth.status, AuthStatus.unauthenticated);
        expect(storage.tokens, isNull);
        expect(google.signOuts, 1);
        expect(
          backend.requests.any((r) => r.url.path.endsWith('/auth/logout')),
          isTrue,
        );
      },
    );

    test('re-login after logout yields the same backend user', () async {
      final storage = InMemoryTokenStorage();
      final backend = FakeBackend()
        ..serveEverything()
        ..on(
          'POST /auth/google/verify',
          (_) => jsonResponse({'accessToken': 'a', 'refreshToken': 'r'}),
        )
        ..on('POST /auth/logout', (_) => jsonResponse({'ok': true}));
      final auth = make(backend, storage, FakeGoogle());
      await auth.signInWithGoogle();
      final first = auth.user!.id;
      await auth.logout();
      await auth.signInWithGoogle();
      expect(auth.user!.id, first);
    });
  });
}
