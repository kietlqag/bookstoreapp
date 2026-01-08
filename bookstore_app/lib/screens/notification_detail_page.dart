import 'package:flutter/material.dart';

import '../models/notification_service.dart';
import '../models/order_service.dart';
import '../models/order.dart';
import '../models/book_service.dart';
import '../models/book.dart';
import '../models/review_service.dart';
import '../models/voucher_service.dart';
import '../models/voucher.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_colors.dart';
import '../widgets/header.dart';
import '../widgets/price_formatter.dart';
import 'order_detail_page.dart';
import 'book_detail_page.dart';

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
  late final BookService _bookService = BookService(baseUrl: widget.baseUrl);
  late final ReviewService _reviewService = ReviewService(baseUrl: widget.baseUrl);
  late final VoucherService _voucherService = VoucherService(baseUrl: widget.baseUrl);
  OrderSummary? _order;
  Book? _book;
  Voucher? _voucher;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isRead = widget.notification.isRead;
    // Load related data based on notification type
    debugPrint('[NotificationDetail] Notification type: ${widget.notification.type}');
    debugPrint('[NotificationDetail] Notification relatedId: ${widget.notification.relatedId}');
    
    if (widget.notification.relatedId != null && widget.notification.relatedId!.isNotEmpty) {
      final relatedId = int.tryParse(widget.notification.relatedId!);
      if (relatedId != null) {
        if (widget.notification.type == 'order' || widget.notification.type == 'order-status-update') {
          _loadOrder();
        } else if (widget.notification.type == 'product' || widget.notification.type == 'new_book') {
          _loadBook();
        } else if (widget.notification.type == 'voucher') {
          _loadVoucher();
        }
        // flash_sale không cần load data, chỉ hiển thị nội dung
      }
    }
  }

  Future<void> _loadOrder() async {
    final orderIdStr = widget.notification.relatedId;
    if (orderIdStr == null || orderIdStr.isEmpty) return;
    
    final orderId = int.tryParse(orderIdStr);
    if (orderId == null) return;
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final order = await _orderService.fetchOrder(
        orderId: orderId,
        userId: widget.userId,
      );
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[NotificationDetail] Error loading order: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBook() async {
    final bookIdStr = widget.notification.relatedId;
    if (bookIdStr == null || bookIdStr.isEmpty) return;
    
    final bookId = int.tryParse(bookIdStr);
    if (bookId == null) return;
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final book = await _bookService.fetchBook(bookId);
      if (mounted) {
        setState(() {
          _book = book;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[NotificationDetail] Error loading book: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadVoucher() async {
    final voucherIdStr = widget.notification.relatedId;
    if (voucherIdStr == null || voucherIdStr.isEmpty) return;
    
    final voucherId = int.tryParse(voucherIdStr);
    if (voucherId == null) return;
    
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final vouchers = await _voucherService.fetchVouchers(activeOnly: false);
      final voucher = vouchers.firstWhere(
        (v) => v.id == voucherId,
        orElse: () => vouchers.isNotEmpty ? vouchers.first : throw Exception('Voucher not found'),
      );
      if (mounted) {
        setState(() {
          _voucher = voucher.id == voucherId ? voucher : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[NotificationDetail] Error loading voucher: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                    // Show related card based on notification type
                    if (widget.notification.relatedId != null &&
                        widget.notification.relatedId!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _buildRelatedCard(),
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

  Widget _buildRelatedCard() {
    // Flash sale: không hiện card, chỉ hiện nội dung
    if (widget.notification.type == 'flash_sale') {
      return const SizedBox.shrink();
    }
    
    // Order notifications
    if (widget.notification.type == 'order' || widget.notification.type == 'order-status-update') {
      if (_isLoading) {
        return Container(
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
        );
      }
      if (_order != null) {
        return _buildOrderCard(_order!);
      }
      return const SizedBox.shrink();
    }
    
    // Product/Book notifications
    if (widget.notification.type == 'product' || widget.notification.type == 'new_book') {
      if (_isLoading) {
        return Container(
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
                'Đang tải thông tin sách...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gray600,
                    ),
              ),
            ],
          ),
        );
      }
      if (_book != null) {
        return _buildBookCard(_book!);
      }
      return const SizedBox.shrink();
    }
    
    // Voucher notifications
    if (widget.notification.type == 'voucher') {
      if (_isLoading) {
        return Container(
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
                'Đang tải thông tin voucher...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.gray600,
                    ),
              ),
            ],
          ),
        );
      }
      if (_voucher != null) {
        return _buildVoucherCard(_voucher!);
      }
      return const SizedBox.shrink();
    }
    
    // Other notifications: no card
    return const SizedBox.shrink();
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

  Widget _buildBookCard(Book book) {
    final discountRate = (book.discount / 100).clamp(0.0, 1.0);
    final finalPrice = (book.price * (1 - discountRate)).clamp(0.0, double.infinity);

    return InkWell(
      onTap: () {
        // Navigate to book detail page when card is clicked
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookDetailPage(
              book: book,
              bookService: _bookService,
              reviewService: _reviewService,
              isFavorite: false, // TODO: Get from favorite service if needed
              onToggleFavorite: (Book b) async {
                // TODO: Implement toggle favorite
                return false;
              },
              onAddToCart: (Book b, int quantity) {
                // TODO: Implement add to cart
              },
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
        child: Row(
          children: [
            // Book image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.cover,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: AppColors.gray200,
                  child: const Icon(Icons.book, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Book info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gray600,
                          fontSize: 12,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (book.discount > 0) ...[
                        Text(
                          '${book.price.toInt()}đ',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.gray500,
                                fontSize: 11,
                                decoration: TextDecoration.lineThrough,
                              ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '${finalPrice.toInt()}đ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.orange600,
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    String discountText = '';
    if (voucher.discountType == 'percent') {
      discountText = 'Giảm ${voucher.discountValue.toInt()}%';
      if (voucher.maxDiscount != null && voucher.maxDiscount! > 0) {
        discountText += ' (tối đa ${formatPrice(voucher.maxDiscount!)})';
      }
    } else if (voucher.discountType == 'amount') {
      discountText = 'Giảm ${formatPrice(voucher.discountValue)}';
    } else if (voucher.discountType == 'shipping') {
      discountText = 'Giảm phí vận chuyển ${formatPrice(voucher.discountValue)}';
    }

    final color = voucher.discountType == 'shipping'
        ? const Color(0xFF14B8A6)
        : voucher.discountType == 'percent'
            ? const Color(0xFFF97316)
            : const Color(0xFFE11D48);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200, width: 1),
      ),
      child: Row(
        children: [
          // Voucher badge
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.local_offer,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  voucher.code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Voucher info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.gray900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  discountText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray700,
                        fontSize: 13,
                      ),
                ),
                if (voucher.minOrderValue > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Đơn tối thiểu: ${formatPrice(voucher.minOrderValue)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gray600,
                          fontSize: 12,
                        ),
                  ),
                ],
                if (voucher.endAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Hết hạn: ${DateFormatter.formatDateShort(voucher.endAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gray600,
                          fontSize: 12,
                        ),
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
