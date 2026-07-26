import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/notifications_provider.dart';

class NotificationSheet extends ConsumerWidget {
  const NotificationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 24),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Notifikasi', style: theme.textTheme.headlineSmall),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('Tidak ada notifikasi.'),
                    ));
                  }
                  return ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    children: notifications.map((notif) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: _buildNotificationItem(context, theme, notif, ref),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, ThemeData theme, NotificationModel notif, WidgetRef ref) {
    Color iconColor;
    IconData icon;
    
    switch (notif.type) {
      case 'FRUGALITY_TRIGGER':
        iconColor = AppColors.error;
        icon = LucideIcons.flame;
        break;
      case 'SYSTEM_INFO':
        iconColor = AppColors.primary;
        icon = LucideIcons.info;
        break;
      default:
        iconColor = AppColors.accent;
        icon = LucideIcons.bell;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notif.isRead ? theme.colorScheme.surface : iconColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: notif.isRead ? theme.dividerColor.withValues(alpha: 0.1) : iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notif.title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: notif.isRead ? null : iconColor)),
                const SizedBox(height: 4),
                Text(
                  notif.message,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                if (!notif.isRead) ...[
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(notificationsProvider.notifier).markAsRead(notif.id);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 32),
                    ),
                    child: const Text('Tandai Dibaca'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
