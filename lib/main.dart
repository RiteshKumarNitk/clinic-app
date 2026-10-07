import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/dependencies.dart';
import 'core/utils/clinic_time.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ClinicTime.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final deps = Dependencies.production();
  // Push is optional: a failure here never blocks launch.
  await deps.push.init().timeout(const Duration(seconds: 5), onTimeout: () {});
  // Session restoration starts immediately; the router holds the splash
  // until it settles, so the login screen never flashes for a signed-in user.
  deps.auth.restore(minimumSplash: const Duration(milliseconds: 1600));
  runApp(ClinicApp(deps: deps));
}
