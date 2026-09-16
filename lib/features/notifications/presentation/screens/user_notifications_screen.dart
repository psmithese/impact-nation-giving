import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/models/app_notification.dart';
import '../../providers/notification_providers.dart';

class UserNotificationsScreen extends ConsumerWidget {
  const UserNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () {
              final user = ref.read(authStateChangesProvider).value;
              if (user != null) {
                ref
                    .read(notificationControllerProvider.notifier)
                    .markAllAsRead(user.uid);
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return ListTile(
                tileColor: notification.isRead ? null : AppColors.primary.withOpacity(0.05),
                leading: CircleAvatar(
                  backgroundColor: notification.isRead ? Colors.grey[200] : AppColors.primary.withOpacity(0.1),
                  child: Icon(
                    _getIconForType(notification.type),
                    color: notification.isRead ? Colors.grey : AppColors.primary,
                  ),
                ),
                title: Text(
                  notification.title,
                  style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notification.body),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(notification.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                onTap: () {
                  if (!notification.isRead) {
                    ref.read(notificationControllerProvider.notifier).markAsRead(notification.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.PAYMENT_SUBMITTED:
        return Icons.upload_rounded;
      case NotificationType.PAYMENT_VERIFIED:
        return Icons.check_circle_rounded;
      case NotificationType.PAYMENT_REJECTED:
        return Icons.cancel_rounded;
      case NotificationType.PLEDGE_CREATED:
        return Icons.handshake_rounded;
      case NotificationType.PLEDGE_REMINDER:
        return Icons.alarm_rounded;
      case NotificationType.CAMPAIGN_MILESTONE:
        return Icons.flag_rounded;
      case NotificationType.CAMPAIGN_COMPLETED:
        return Icons.emoji_events_rounded;
      case NotificationType.ANNOUNCEMENT:
        return Icons.campaign_rounded;
    }
  }
}
