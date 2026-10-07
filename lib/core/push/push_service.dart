import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_client.dart';

/// What a tapped notification asks the app to open.
typedef PushOpenHandler = void Function(Map<String, dynamic> data);

/// Push notifications for the signed-in patient. Abstract so tests (and
/// builds without Firebase config) use the no-op version.
abstract class PushService {
  Future<void> init();

  /// Ask for permission (Android 13+/iOS) and register this phone.
  Future<void> registerDevice();

  /// Stop pushes to this phone (call before the session is revoked).
  Future<void> unregisterDevice();

  /// Set once the router exists; a tap that launched the app is replayed.
  set onOpen(PushOpenHandler handler);
}

class NoopPushService implements PushService {
  @override
  Future<void> init() async {}
  @override
  Future<void> registerDevice() async {}
  @override
  Future<void> unregisterDevice() async {}
  @override
  set onOpen(PushOpenHandler handler) {}
}

/// Firebase Cloud Messaging. While the app is in the background the system
/// shows pushes itself; in the foreground we show them via a local
/// notification so they are never silently swallowed.
class FirebasePushService implements PushService {
  FirebasePushService(this._api);

  final ApiClient _api;
  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _token;
  PushOpenHandler? _onOpen;
  Map<String, dynamic>? _pendingOpen;

  static const _channel = AndroidNotificationChannel(
    'clinic_updates',
    'Clinic updates',
    description: 'Appointment confirmations, reminders and queue updates.',
    importance: Importance.high,
  );

  @override
  set onOpen(PushOpenHandler handler) {
    _onOpen = handler;
    final pending = _pendingOpen;
    if (pending != null) {
      _pendingOpen = null;
      handler(pending);
    }
  }

  void _open(Map<String, dynamic> data) {
    final handler = _onOpen;
    if (handler == null) {
      _pendingOpen = data;
    } else {
      handler(data);
    }
  }

  @override
  Future<void> init() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      developer.log(
        'Firebase unavailable; push disabled',
        name: 'Push',
        error: e,
      );
      return;
    }
    _ready = true;

    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        final payload = r.payload;
        if (payload == null) return;
        try {
          _open(jsonDecode(payload) as Map<String, dynamic>);
        } catch (_) {}
      },
    );
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    final messaging = FirebaseMessaging.instance;
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n == null) return;
      _local.show(
        id: m.hashCode,
        title: n.title,
        body: n.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(m.data),
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data));
    final initial = await messaging.getInitialMessage();
    if (initial != null) _open(initial.data);
    messaging.onTokenRefresh.listen((t) => _send(t));
  }

  @override
  Future<void> registerDevice() async {
    if (!_ready) return;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _send(token);
    } catch (e) {
      developer.log('Push registration failed', name: 'Push', error: e);
    }
  }

  Future<void> _send(String token) async {
    _token = token;
    try {
      await _api.post(
        '/me/devices',
        body: {'token': token, 'platform': Platform.isIOS ? 'ios' : 'android'},
      );
    } catch (e) {
      developer.log('Device register failed', name: 'Push', error: e);
    }
  }

  @override
  Future<void> unregisterDevice() async {
    final token = _token;
    if (!_ready || token == null) return;
    _token = null;
    try {
      await _api.delete('/me/devices', body: {'token': token});
    } catch (_) {
      // The server drops dead tokens on its own; logout must not block.
    }
  }
}
