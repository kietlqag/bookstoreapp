import 'package:flutter/material.dart';

import '../models/notification_service.dart';
import '../models/order_service.dart';
import '../models/order.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_colors.dart';
import 'notification_detail_page.dart';
import 'order_detail_page.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({
    super.key,
    required this.baseUrl,
    required this.token,
    required this.userId,
  });

  final String baseUrl;
  final String token;
  final int userId;

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  late final NotificationService _notificationService =
      NotificationService(baseUrl: widget.baseUrl, token: widget.token);
  late final OrderService _orderService = OrderService(baseUrl: widget.baseUrl);

  List<NotificationItem> _notifications = [];
  Map<int, OrderSummary?> _orderCache = {}; // Cache orders by orderId
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final notifications = await _notificationService.getNotifications(includeRead: true);
      if (!mounted) return;
      
      // Pre-load order data for order notifications
      final orderNotifications = notifications
          .where((n) => n.notificationType == NotificationType.order && n.relatedId != null)
          .toList();
      
      for (final notification in orderNotifications) {
        if (notification.relatedId != null) {
          final orderId = int.tryParse(notification.relatedId!);
          if (orderId != null && !_orderCache.containsKey(orderId)) {
            try {
              final order = await _orderService.fetchOrder(
                orderId: orderId,
                userId: widget.userId,
              );
              _orderCache[orderId] = order;
            } catch (e) {
              _orderCache[orderId] = null;
            }
          }
        }
      }
      
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshNotifications() async {
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      if (!mounted) return;
      await _loadNotifications(); // Reload để cập nhật UI
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã đánh dấu tất cả thông báo là đã đọc'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: ${error.toString()}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thông báo'),
        centerTitle: false,
        toolbarHeight: 44,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.orange600,
                AppColors.rose500,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // Mark all as read button - sát mép phải
          if (_notifications.any((n) => !n.isRead))
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: _markAllAsRead,
                icon: const Icon(
                  Icons.done_all,
                  size: 14,
                  color: Colors.white,
                ),
                label: const Text(
                  'Đọc tất cả',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.orange600,
                        ),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadNotifications,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : _notifications.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _refreshNotifications,
                              color: AppColors.orange600,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _notifications.length,
                                itemBuilder: (context, index) {
                                  final notification = _notifications[index];
                                  return _buildNotificationCard(notification);
                                },
                              ),
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
    
    switch (notification.notificationType) {
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
        // Always navigate to notification detail page first
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NotificationDetailPage(
              notification: notification,
              baseUrl: widget.baseUrl,
              token: widget.token,
              userId: widget.userId,
              onMarkAsRead: () async {
                await _loadNotifications(); // Reload để cập nhật UI
              },
              onDelete: () async {
                await _loadNotifications(); // Reload để cập nhật UI
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
                  DateFormatter.formatRelativeTime(notification.createdAt),
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

  Future<OrderSummary?> _loadOrderForNotification(String orderIdStr) async {
    final orderId = int.tryParse(orderIdStr);
    if (orderId == null) return null;
    
    // Check cache first
    if (_orderCache.containsKey(orderId)) {
      return _orderCache[orderId];
    }
    
    try {
      final order = await _orderService.fetchOrder(
        orderId: orderId,
        userId: widget.userId,
      );
      _orderCache[orderId] = order;
      return order;
    } catch (e) {
      _orderCache[orderId] = null;
      return null;
    }
  }

  Widget _buildOrderCard(OrderSummary order) {
    if (order.items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Show first 3 items
    final displayItems = order.items.take(3).toList();
    final remainingCount = order.items.length - displayItems.length;
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 16,
                color: AppColors.orange600,
              ),
              const SizedBox(width: 6),
              Text(
                'Đơn hàng #${order.id}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.orange600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...displayItems.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    // Product image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        item.bookImageUrl ?? '',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 40,
                          height: 40,
                          color: AppColors.gray200,
                          child: const Icon(Icons.book, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Product info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.bookTitle ?? 'Sản phẩm',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray900,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Số lượng: ${item.quantity}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.gray600,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
          if (remainingCount > 0)
            Text(
              'và $remainingCount sản phẩm khác',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.gray600,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
            ),
        ],
      ),
    );
  }

}

