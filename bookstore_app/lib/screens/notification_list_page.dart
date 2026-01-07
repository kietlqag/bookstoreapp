import 'package:flutter/material.dart';

import '../widgets/app_colors.dart';
import '../widgets/header.dart';
import 'notification_detail_page.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  // TODO: Replace with actual notification data from API
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'Đơn hàng đã được xác nhận',
      message: 'Đơn hàng #12345 của bạn đã được xác nhận và đang được chuẩn bị.',
      time: DateTime.now().subtract(const Duration(minutes: 10)),
      isRead: false,
      type: NotificationType.order,
    ),
    NotificationItem(
      id: '2',
      title: 'Khuyến mãi đặc biệt',
      message: 'Giảm 20% cho tất cả sách văn học trong tuần này!',
      time: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: NotificationType.promotion,
    ),
    NotificationItem(
      id: '3',
      title: 'Đơn hàng đang được giao',
      message: 'Đơn hàng #12340 của bạn đang trên đường giao đến bạn.',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.order,
    ),
    NotificationItem(
      id: '4',
      title: 'Sách yêu thích đã có hàng',
      message: '"Sách ABC" trong danh sách yêu thích của bạn đã có hàng trở lại.',
      time: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      type: NotificationType.product,
    ),
  ];

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = NotificationItem(
            id: _notifications[i].id,
            title: _notifications[i].title,
            message: _notifications[i].message,
            time: _notifications[i].time,
            isRead: true,
            type: _notifications[i].type,
          );
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã đánh dấu tất cả thông báo là đã đọc'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            HeaderBar(
              title: 'Thông báo',
              showBack: true,
              onBack: () => Navigator.of(context).pop(),
              backgroundGradient: LinearGradient(
                colors: [
                  AppColors.orange600,
                  AppColors.rose500,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              titleColor: Colors.white,
              iconColor: Colors.white,
              actions: const [], // Bỏ icon chuông và tim
            ),
            Expanded(
              child: _notifications.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 64,
            color: AppColors.gray400,
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có thông báo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.gray600,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Các thông báo sẽ xuất hiện tại đây',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    IconData icon;
    Color iconColor;
    
    switch (notification.type) {
      case NotificationType.order:
        icon = Icons.local_shipping_outlined;
        iconColor = AppColors.orange600;
        break;
      case NotificationType.promotion:
        icon = Icons.local_offer_outlined;
        iconColor = AppColors.rose500;
        break;
      case NotificationType.product:
        icon = Icons.book_outlined;
        iconColor = AppColors.teal600;
        break;
      default:
        icon = Icons.info_outline;
        iconColor = AppColors.gray600;
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NotificationDetailPage(
              notification: notification,
              onMarkAsRead: () {
                setState(() {
                  // Update notification status in list
                  final index = _notifications.indexWhere((n) => n.id == notification.id);
                  if (index != -1) {
                    _notifications[index] = NotificationItem(
                      id: notification.id,
                      title: notification.title,
                      message: notification.message,
                      time: notification.time,
                      isRead: true,
                      type: notification.type,
                    );
                  }
                });
              },
              onDelete: () {
                setState(() {
                  _notifications.removeWhere((n) => n.id == notification.id);
                });
              },
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : AppColors.orange50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead ? AppColors.gray200 : AppColors.orange200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: AppColors.gray900,
                            ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.orange600,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray600,
                        height: 1.4,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(notification.time),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray500,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Vừa xong';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} phút trước';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

enum NotificationType {
  order,
  promotion,
  product,
  system,
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });

  final String id;
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final NotificationType type;
}
