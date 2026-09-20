import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../domain/models/app_notification.dart';
import '../../providers/notification_providers.dart';

class UserNotificationsScreen extends ConsumerWidget {
  const UserNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, h:mm a');

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Notifications'),
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
        error: (e, _) => Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see updates here when they arrive.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final isUnread = !notification.isRead;

              return InkWell(
                onTap: () {
                  if (isUnread) {
                    ref
                        .read(notificationControllerProvider.notifier)
                        .markAsRead(notification.id);
                  }
                },
                child: Container(
                  color: isUnread
                      ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                      : null,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isUnread
                              ? colorScheme.primaryContainer
                              : colorScheme.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconForType(notification.type),
                          color: isUnread
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Text content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (isUnread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin:
                                        const EdgeInsets.only(left: 8, top: 2),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notification.body,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              dateFormat.format(notification.createdAt),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
