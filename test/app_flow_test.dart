import 'package:clinic_app/app/app.dart';
import 'package:clinic_app/app/dependencies.dart';
import 'package:clinic_app/core/network/api_client.dart';
import 'package:clinic_app/core/storage/token_storage.dart';
import 'package:clinic_app/core/utils/clinic_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// Builds the real app (real router, guard, screens, repositories) on top of
/// a scripted backend.
Future<(Dependencies, FakeBackend)> pumpApp(
  WidgetTester tester, {
  SessionTokens? session,
}) async {
  final backend = FakeBackend()
    ..serveEverything()
    ..on(
      'POST /auth/google/verify',
      (_) => jsonResponse({'accessToken': 'acc-1', 'refreshToken': 'ref-1'}),
    )
    ..on('POST /auth/logout', (_) => jsonResponse({'ok': true}));
  final storage = InMemoryTokenStorage(session);
  final deps = Dependencies.from(
    storage: storage,
    google: FakeGoogle(),
    api: ApiClient(
      storage: storage,
      httpClient: backend.client,
      baseUrl: 'https://x.test/api',
    ),
  );
  await tester.binding.setSurfaceSize(const Size(420, 900));
  await tester.pumpWidget(ClinicApp(deps: deps));
  await deps.auth.restore();
  await tester.pumpAndSettle();
  return (deps, backend);
}

void main() {
  setUpAll(ClinicTime.ensureInitialized);

  testWidgets('fresh install shows only Continue with Google', (tester) async {
    await pumpApp(tester);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing); // no email/password
  });

  testWidgets('Google login → Home with real clinic data', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Asha'), findsWidgets);
    expect(find.text('Find healthcare'), findsWidgets);
    expect(
      find.text('Demo Clinic (synthetic data — not real patients)'),
      findsWidgets,
    );
  });

  testWidgets(
    'restored session: every tab and the full flow open with no login',
    (tester) async {
      await pumpApp(
        tester,
        session: const SessionTokens(accessToken: 'a', refreshToken: 'r'),
      );
      Future<void> noLogin() async {
        await tester.pumpAndSettle();
        expect(find.text('Continue with Google'), findsNothing);
      }

      await noLogin();
      expect(find.text('Upcoming appointment'), findsOneWidget);

      await tester.tap(find.text('Appointments'));
      await noLogin();
      expect(find.text('My appointments'), findsOneWidget);
      expect(find.text('Dr. Demo Sharma'), findsWidgets);

      await tester.tap(find.text('Find'));
      await noLogin();
      await tester.tap(
        find.text('Demo Clinic (synthetic data — not real patients)').first,
      );
      await noLogin();
      expect(find.text('Consultation · 15 min'), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Dr. Demo Sharma'), 200);
      await tester.tap(find.text('Dr. Demo Sharma'));
      await noLogin();
      expect(find.text('Book appointment'), findsOneWidget);

      await tester.tap(find.text('Book appointment'));
      await noLogin();
      expect(find.text('Type of visit'), findsOneWidget);
      await tester.tap(find.text('Choose a time'));
      await noLogin();
      expect(find.text('Pick a date & time'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await tester.pageBack();
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Profile'));
      await noLogin();
      expect(find.text('asha@example.com'), findsOneWidget);
    },
  );

  testWidgets('logout from Profile → protected screens require Google again', (
    tester,
  ) async {
    final (deps, _) = await pumpApp(
      tester,
      session: const SessionTokens(accessToken: 'a', refreshToken: 'r'),
    );
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(deps.auth.isAuthenticated, isFalse);
  });

  testWidgets('live queue renders server numbers', (tester) async {
    final (deps, _) = await pumpApp(
      tester,
      session: const SessionTokens(accessToken: 'a', refreshToken: 'r'),
    );
    final router = tester
        .widget<MaterialApp>(find.byType(MaterialApp))
        .routerConfig!;
    (router as dynamic).push('/queue/appt-t?org=$orgId');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('#12'), findsOneWidget);
    expect(find.text('#9'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('WAITING'), findsOneWidget);
    // Stop the polling timer.
    await tester.pumpWidget(const SizedBox());
    deps.auth.dispose();
  });
}
