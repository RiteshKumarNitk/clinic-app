import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/auth/auth_controller.dart';
import 'dependencies.dart';
import 'router.dart';
import 'theme.dart';

class ClinicApp extends StatefulWidget {
  const ClinicApp({super.key, required this.deps});

  final Dependencies deps;

  @override
  State<ClinicApp> createState() => _ClinicAppState();
}

class _ClinicAppState extends State<ClinicApp> {
  late final GoRouter _router = buildRouter(widget.deps.auth);

  @override
  void initState() {
    super.initState();
    // A tapped push opens the right screen (replayed if it launched the app).
    widget.deps.push.onOpen = _openFromPush;
  }

  void _openFromPush(Map<String, dynamic> data) {
    final auth = widget.deps.auth;
    // Launched from a push: wait for the saved session to be restored.
    if (auth.status == AuthStatus.unknown) {
      late final VoidCallback once;
      once = () {
        if (auth.status == AuthStatus.unknown) return;
        auth.removeListener(once);
        _openFromPush(data);
      };
      auth.addListener(once);
      return;
    }
    if (!auth.isAuthenticated) return;
    {
      final appointmentId = data['appointmentId'];
      if (data['event'] == 'QUEUE_UPDATE' &&
          appointmentId is String &&
          appointmentId.isNotEmpty) {
        _router.push(Routes.queue(appointmentId));
      } else {
        _router.push(Routes.notifications);
      }
    }
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.deps;
    return MultiProvider(
      providers: [
        Provider.value(value: d),
        ChangeNotifierProvider.value(value: d.auth),
        ChangeNotifierProvider.value(value: d.appointmentsChanged),
        Provider.value(value: d.clinics),
        Provider.value(value: d.doctors),
        Provider.value(value: d.appointments),
        Provider.value(value: d.queue),
        Provider.value(value: d.records),
        Provider.value(value: d.notifications),
      ],
      child: MaterialApp.router(
        title: 'CityCare',
        debugShowCheckedModeBanner: false,
        theme: buildClinicTheme(),
        routerConfig: _router,
      ),
    );
  }
}
