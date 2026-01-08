import 'package:flutter/material.dart';

import '../models/notification_service.dart';
import '../models/order_service.dart';
import '../models/order.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_colors.dart';
import '../widgets/header.dart';
import 'order_detail_page.dart';

class NotificationDetailPage extends StatefulWidget {
  const NotificationDetailPage({
    super.key,
    required this.notification,
    required this.baseUrl,
    required this.token,
    required this.userId,
    this.onMarkAsRead,
    this.onDelete,
  });

  final NotificationItem notification;
  final String baseUrl;
  final String token;
  final int userId;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  @override
  State<NotificationDetailPage> createState() => _NotificationDetailPageState();
}

class _NotificationDetailPageState extends State<NotificationDetailPage> {
  late bool _isRead;
  late final OrderService _orderService = OrderService(baseUrl: widget.baseUrl);
  OrderSummary? _order;

  @override
  void initState() {
    super.initState();
    _isRead = widget.notification.isRead;
    // Load order if notification is order type
    debugPrint('[NotificationDetail] Notification type: ${widget.notification.type}');
    debugPrint('[NotificationDetail] Notification relatedId: ${widget.notification.relatedId}');
    debugPrint('[NotificationDetail] Notification type enum: ${widget.notification.notificationType}');
    // Try to load order if relatedId exists (could be order notification)
    if (widget.notification.relatedId != null && widget.notification.relatedId!.isNotEmpty) {
      // Check if relatedId is a number (likely order ID)
      final orderId = int.tryParse(widget.notification.relatedId!);
      if (orderId != null) {
        _loadOrder();
      } else {
        debugPrint('[NotificationDetail] relatedId is not a valid order ID: ${widget.notification.relatedId}');
      }
    } else {
      debugPrint('[NotificationDetail] Skipping order load - no relatedId');
    }
  }

  Future<void> _loadOrder() async {
    final orderIdStr = widget.notification.relatedId;
    if (orderIdStr == null || orderIdStr.isEmpty) {
      debugPrint('[NotificationDetail] relatedId is null or empty');
      return;
    }
    
    final orderId = int.tryParse(orderIdStr);
    if (orderId == null) {
      debugPrint('[NotificationDetail] Cannot parse relatedId to int: $orderIdStr');
      return;
    }
    
    debugPrint('[NotificationDetail] Loading order ID: $orderId for user: ${widget.userId}');
    try {
      final order = await _orderService.fetchOrder(
        orderId: orderId,
        userId: widget.userId,
      );
      debugPrint('[NotificationDetail] Order loaded: ${order != null ? "Success" : "Null"}');
      if (order != null) {
        debugPrint('[NotificationDetail] Order has ${order.items.length} items');
      }
      if (mounted) {
        setState(() {
          _order = order;
        });
      }
    } catch (e) {
      debugPrint('[NotificationDetail] Error loading order: $e');
      // Order not found or error
    }
  }

  Future<void> _handleMarkAsRead() async {
    if (!_isRead) {
      try {
        final service = NotificationService(
          baseUrl: widget.baseUrl,
          token: widget.token,
        );
        await service.markAsRead(widget.notification.id);
        if (!mounted) return;
        setState(() {
          _isRead = true;
        });
        if (widget.onMarkAsRead != null) {
          widget.onMarkAsRead!();
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đánh dấu là đã đọc'),
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
  }

  Future<void> _handleDelete() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thông báo'),
        content: const Text('Bạn có chắc chắn muốn xóa thông báo này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final service = NotificationService(
                  baseUrl: widget.baseUrl,
                  token: widget.token,
                );
                await service.deleteNotification(widget.notification.id);
                if (!mounted) return;
                if (widget.onDelete != null) {
                  widget.onDelete!();
                }
                Navigator.of(context).pop();
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa thông báo'),
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
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Icons.local_shipping_outlined;
      case NotificationType.promotion:
        return Icons.local_offer_outlined;
      case NotificationType.product:
        return Icons.book_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return AppColors.orange600;
      case NotificationType.promotion:
        return AppColors.rose500;
      case NotificationType.product:
        return AppColors.teal600;
      default:
        return AppColors.gray600;
    }
  }


  @override
  Widget build(BuildContext context) {
    final icon = _getIcon(widget.notification.notificationType);
    final iconColor = _getIconColor(widget.notification.notificationType);

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
              actions: const [],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon và tiêu đề
                    Row(
                      children: [
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.notification.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray900,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormatter.formatRelativeTime(widget.notification.createdAt),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.gray500,
                                      fontSize: 12,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Nội dung thông báo
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isRead ? AppColors.gray50 : AppColors.orange50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isRead
                              ? AppColors.gray200
                              : AppColors.orange200.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.notification.message,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.gray700,
                              height: 1.5,
                              fontSize: 14,
                            ),
                      ),
                    ),
                    // Show order card if we have relatedId (could be order)
                    if (widget.notification.relatedId != null &&
                        int.tryParse(widget.notification.relatedId!) != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _order != null
                            ? _buildOrderCard(_order!)
                            : Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.gray50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.gray200, width: 1),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Đang tải thông tin đơn hàng...',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: AppColors.gray600,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    const SizedBox(height: 24),
                    // Các nút hành động
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isRead ? null : _handleMarkAsRead,
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: _isRead
                                    ? AppColors.gray300
                                    : AppColors.orange600,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: _isRead
                                  ? Colors.transparent
                                  : Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                  color: _isRead
                                      ? AppColors.gray400
                                      : AppColors.orange600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Đánh dấu đã đọc',
                                  style: TextStyle(
                                    color: _isRead
                                        ? AppColors.gray400
                                        : AppColors.orange600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _handleDelete,
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                color: Colors.red,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Xóa',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderSummary order) {
    if (order.items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Show first 3 items
    final displayItems = order.items.take(3).toList();
    final remainingCount = order.items.length - displayItems.length;
    
    return InkWell(
      onTap: () {
        // Navigate to order detail page when card is clicked
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OrderDetailPage(
              order: order,
              userId: widget.userId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.gray50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gray200, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: AppColors.orange600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Đơn hàng #${order.id}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange600,
                      ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppColors.gray400,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...displayItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      // Product image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.bookImageUrl ?? '',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 50,
                            height: 50,
                            color: AppColors.gray200,
                            child: const Icon(Icons.book, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Product info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.bookTitle ?? 'Sản phẩm',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.gray900,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Số lượng: ${item.quantity}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.gray600,
                                    fontSize: 12,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            if (remainingCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'và $remainingCount sản phẩm khác',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray600,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
