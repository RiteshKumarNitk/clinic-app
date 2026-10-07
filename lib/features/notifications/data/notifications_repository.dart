import '../../../core/network/api_client.dart';
import '../../../core/utils/json.dart';
import '../../appointments/data/appointment_models.dart';
import '../../appointments/data/appointment_repository.dart';

/// One entry in the notification inbox.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.organizationId,
    required this.message,
    required this.createdAt,
    required this.read,
    this.clinicName,
    this.appointmentId,
  });

  final String id;
  final String organizationId;
  final String message;
  final DateTime createdAt;
  final bool read;
  final String? clinicName;
  final String? appointmentId;

  factory AppNotification.fromJson(Json j, MyClinic clinic) {
    final href = str(j, 'href');
    // Server hrefs look like "appointments/<id>".
    final appointmentId = href != null && href.startsWith('appointments/')
        ? href.substring('appointments/'.length)
        : null;
    return AppNotification(
      id: reqStr(j, 'id'),
      organizationId: clinic.id,
      clinicName: clinic.name,
      message: str(j, 'message') ?? 'Update',
      createdAt: date(j, 'createdAt') ?? DateTime.now().toUtc(),
      read: boolOr(j, 'read', true),
      appointmentId: appointmentId,
    );
  }
}

class NotificationInbox {
  const NotificationInbox({required this.items, required this.unreadCount});

  final List<AppNotification> items;
  final int unreadCount;
}

/// In-app notifications are kept per clinic on the server; this merges them.
class NotificationsRepository {
  NotificationsRepository(this._api, this._appointments);

  final ApiClient _api;
  final AppointmentRepository _appointments;
  List<MyClinic>? _clinics;

  Future<List<MyClinic>> _myClinics({bool refresh = false}) async =>
      refresh || _clinics == null
      ? _clinics = await _appointments.myClinics()
      : _clinics!;

  Future<NotificationInbox> inbox({bool refresh = true}) async {
    final clinics = await _myClinics(refresh: refresh);
    final results = await Future.wait(
      clinics.map((c) async {
        final json = await _api.get(
          '/orgs/${Uri.encodeComponent(c.id)}/notifications',
          auth: Auth.required,
          query: const {'limit': '30'},
        );
        final items = objList(
          json,
          'data',
        ).map((j) => AppNotification.fromJson(j, c)).toList();
        return (items, intOrNull(json, 'unreadCount') ?? 0);
      }),
    );
    final items = results.expand((r) => r.$1).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final unread = results.fold<int>(0, (sum, r) => sum + r.$2);
    return NotificationInbox(items: items, unreadCount: unread);
  }

  Future<void> markAllRead() async {
    final clinics = await _myClinics();
    await Future.wait(
      clinics.map(
        (c) => _api.post(
          '/orgs/${Uri.encodeComponent(c.id)}/notifications/read',
          body: const {},
        ),
      ),
    );
  }
}
