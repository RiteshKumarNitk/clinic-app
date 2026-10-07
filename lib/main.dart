import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'app/dependencies.dart';
import 'core/utils/clinic_time.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ClinicTime.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final deps = Dependencies.production();
  // Session restoration starts immediately; the router holds the splash
  // until it settles, so the login screen never flashes for a signed-in user.
  deps.auth.restore();
  runApp(ClinicApp(deps: deps));
}
