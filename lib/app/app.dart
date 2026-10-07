import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
      ],
      child: MaterialApp.router(
        title: 'Clinic',
        debugShowCheckedModeBanner: false,
        theme: buildClinicTheme(),
        routerConfig: _router,
      ),
    );
  }
}
