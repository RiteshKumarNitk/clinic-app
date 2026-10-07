import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../data/notifications_repository.dart';

/// Notification inbox — booking confirmations, reminders and updates from
/// every clinic the patient uses. Opening it marks everything read.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final _repo = context.read<NotificationsRepository>();

  Future<NotificationInbox> _load() async {
    final inbox = await _repo.inbox();
    if (inbox.unreadCount > 0) {
      // Fire-and-forget: the list already shows what was unread.
      _repo.markAllRead().catchError((_) {});
    }
    return inbox;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: AsyncView<NotificationInbox>(
        load: _load,
        errorMessage: "We couldn't load your notifications.",
        builder: (context, inbox, reload) => RefreshIndicator(
          onRefresh: reload,
          child: inbox.items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 480,
                      child: CityCareEmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: "You're all caught up",
                        message:
                            'Booking confirmations, reminders and queue updates '
                            'will appear here.',
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(CityCareSpacing.gutter),
                  itemCount: inbox.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: CityCareSpacing.sm),
                  itemBuilder: (_, i) => _Tile(item: inbox.items[i]),
                ),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item});

  final AppNotification item;

  IconData get _icon {
    final m = item.message.toLowerCase();
    if (m.contains('reminder')) return Icons.alarm_rounded;
    if (m.contains('cancel')) return Icons.event_busy_rounded;
    if (m.contains('reschedul')) return Icons.update_rounded;
    if (m.contains('queue') || m.contains('check')) {
      return Icons.confirmation_number_outlined;
    }
    return Icons.event_available_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final local = item.createdAt.toLocal();
    final when = DateTime.now().difference(local).inDays < 1
        ? DateFormat('h:mm a').format(local)
        : DateFormat('d MMM, h:mm a').format(local);
    return Card(
      color: item.read ? CityCareColors.surface : CityCareColors.primarySoft,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.appointmentId == null
            ? null
            : () => context.push(
                Routes.appointment(item.organizationId, item.appointmentId!),
              ),
        child: Padding(
          padding: const EdgeInsets.all(CityCareSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.read
                      ? CityCareColors.primarySoft
                      : CityCareColors.surface,
                  borderRadius: BorderRadius.circular(CityCareRadius.sm),
                ),
                child: Icon(_icon, color: CityCareColors.primary, size: 22),
              ),
              const SizedBox(width: CityCareSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.message, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      [item.clinicName, when].whereType<String>().join(' · '),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!item.read)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: CityCareColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
