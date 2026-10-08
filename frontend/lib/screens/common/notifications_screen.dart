import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/notification_model.dart';
import '../../providers/locale_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/empty_state_view.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    });
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'ATTENDANCE':
        return Icons.access_time_filled_rounded;
      case 'TASK':
        return Icons.assignment_turned_in_rounded;
      case 'LEAVE':
        return Icons.event_available_rounded;
      case 'SALARY':
        return Icons.account_balance_wallet_rounded;
      case 'EXPENSE':
        return Icons.receipt_long_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ATTENDANCE':
        return AppColors.primary;
      case 'TASK':
        return AppColors.purple;
      case 'LEAVE':
        return AppColors.secondary;
      case 'SALARY':
        return AppColors.success;
      case 'EXPENSE':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProv = Provider.of<LocaleProvider>(context);
    final notifProv = Provider.of<NotificationProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(localeProv.tr('notifications')),
        actions: [
          if (notifProv.notifications.isNotEmpty)
            TextButton(
              onPressed: () => notifProv.markAllAsRead(),
              child: Text(
                localeProv.tr('mark_all_read'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: notifProv.isLoading && notifProv.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : notifProv.notifications.isEmpty
              ? EmptyStateView(
                  icon: Icons.notifications_none_rounded,
                  title: localeProv.tr('no_notifications'),
                  buttonText: localeProv.tr('refresh'),
                  onButtonPressed: () => notifProv.fetchNotifications(),
                )
              : RefreshIndicator(
                  onRefresh: () => notifProv.fetchNotifications(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: notifProv.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = notifProv.notifications[index];
                      final color = _getTypeColor(notif.type);

                      return InkWell(
                        onTap: () {
                          if (!notif.isRead) {
                            notifProv.markAsRead(notif.id);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: notif.isRead
                                ? (isDark ? AppColors.surfaceDark : Colors.white)
                                : (isDark ? AppColors.primary.withOpacity(0.12) : AppColors.primary.withOpacity(0.06)),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: notif.isRead
                                  ? (isDark ? AppColors.borderDark : AppColors.borderLight)
                                  : AppColors.primary.withOpacity(0.4),
                              width: notif.isRead ? 1 : 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(_getTypeIcon(notif.type), color: color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                            ),
                                          ),
                                        ),
                                        if (!notif.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.message,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      DateFormat('MMM d, h:mm a').format(notif.createdAt),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
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
                  ),
                ),
    );
  }
}
