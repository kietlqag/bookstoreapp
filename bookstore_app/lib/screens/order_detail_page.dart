import 'dart:io';

import 'package:flutter/material.dart';

import '../models/address.dart';
import '../models/address_service.dart';
import '../models/cart_service.dart';
import '../models/order.dart';
import '../models/order_service.dart';
import '../models/review_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_colors.dart';
import '../widgets/price_formatter.dart';
import '../widgets/top_message.dart';
import 'address_list_page.dart';
import 'home_page.dart';
import 'review_order_page.dart';
import 'support_request_page.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.order,
    required this.userId,
    this.onOrderUpdated,
  });

  final OrderSummary order;
  final int userId;
  final VoidCallback? onOrderUpdated;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _expandedItems = false;
  bool _updatingAddress = false;
  bool _addressUpdated = false;
  bool _cancelling = false;
  bool _markingReceived = false;
  bool _reviewed = false;
  late String _addressNew;
  late String _addressOld;
  late String _recipientName;
  late String _phoneNumber;
  late String _currentStatus;
  late final AddressService _addressService =
      AddressService(baseUrl: _resolveBaseUrl());
  late final OrderService _orderService =
      OrderService(baseUrl: _resolveBaseUrl());
  late final ReviewService _reviewService =
      ReviewService(baseUrl: _resolveBaseUrl());
  late final CartService _cartService =
      CartService(baseUrl: _resolveBaseUrl());
  OrderSummary? _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _addressNew = widget.order.shippingAddressNew;
    _addressOld = widget.order.shippingAddressOld;
    _recipientName = widget.order.recipientName;
    _phoneNumber = widget.order.phoneNumber;
    _currentStatus = widget.order.status;
    _reviewed = widget.order.isReviewed;
  }

  Future<bool> _reloadOrder() async {
    try {
      final updatedOrder = await _orderService.fetchOrder(
        orderId: widget.order.id,
        userId: widget.userId,
      );
      if (!mounted) return false;
      final statusChanged = _currentStatus != updatedOrder.status;
      setState(() {
        _currentOrder = updatedOrder;
        _addressNew = updatedOrder.shippingAddressNew;
        _addressOld = updatedOrder.shippingAddressOld;
        _recipientName = updatedOrder.recipientName;
        _phoneNumber = updatedOrder.phoneNumber;
        _currentStatus = updatedOrder.status;
        _reviewed = updatedOrder.isReviewed;
      });
      widget.onOrderUpdated?.call();
      return statusChanged;
    } catch (_) {
      // Ignore reload errors, keep current state
      return false;
    }
  }

  static String _resolveBaseUrl() {
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }
    if (Platform.isAndroid) {
      return 'http://192.168.1.155:8080';
    }
    return 'http://localhost:8080';
  }

  Future<void> _handleChangeAddress() async {
    if (_updatingAddress) return;
    setState(() => _updatingAddress = true);
    try {
      final addresses = await _addressService.fetchAddresses(widget.userId);
      if (!mounted) return;
      if (addresses.isEmpty) {
        _showMessage('Chưa có địa chỉ để chọn.');
        return;
      }
      final selection = await Navigator.of(context).push<AddressSelection>(
        MaterialPageRoute(
          builder: (_) => AddressListPage(
            addresses: addresses,
            selectedAddressId: addresses.first.id,
            userId: widget.userId,
          ),
        ),
      );
      if (!mounted || selection == null) return;
      final selected = selection.address;
      final newAddress = selected.addressLineNew?.trim().isNotEmpty == true
          ? selected.addressLineNew!
          : selected.addressLine;
      final oldAddress = selected.addressLine;
      await _orderService.updateOrderAddress(
        orderId: widget.order.id,
        userId: widget.userId,
        shippingAddressNew: newAddress,
        shippingAddressOld: oldAddress,
        recipientName: selected.fullName,
        phoneNumber: selected.phoneNumber,
      );
      if (!mounted) return;
      await _reloadOrder();
      setState(() {
        _addressUpdated = true;
      });
      widget.onOrderUpdated?.call();
    } catch (_) {
      if (!mounted) return;
      _showMessage('Không cập nhật được địa chỉ.');
    } finally {
      if (mounted) {
        setState(() => _updatingAddress = false);
      }
    }
  }

  Future<void> _confirmCancelOrder() async {
    if (_cancelling) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy đơn'),
        content: const Text('Bạn có chắc muốn hủy đơn hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.orange600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _cancelling = true);
    try {
      await _orderService.cancelOrder(
        orderId: widget.order.id,
        userId: widget.userId,
      );
      if (!mounted) return;
      final updated = await _reloadOrder();
      _showMessage('Đã hủy đơn hàng.');
      if (updated && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage('Đã xảy ra lỗi. Vui lòng thử lại sau.');
    } finally {
      if (mounted) {
        setState(() => _cancelling = false);
      }
    }
  }

  Future<void> _markOrderReceived() async {
    if (_markingReceived) return;
    setState(() => _markingReceived = true);
    try {
      await _orderService.markOrderDelivered(
        orderId: widget.order.id,
        userId: widget.userId,
      );
      if (!mounted) return;
      final updated = await _reloadOrder();
      _showMessage('Đã xác nhận nhận hàng.');
      if (updated && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      _showMessage('Đã xảy ra lỗi. Vui lòng thử lại sau.');
    } finally {
      if (mounted) {
        setState(() => _markingReceived = false);
      }
    }
  }

  Future<void> _openReviewPage() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewOrderPage(
          order: _currentOrder ?? widget.order,
          userId: widget.userId,
          reviewService: _reviewService,
        ),
      ),
    );
      if (!mounted || submitted != true) return;
      await _reloadOrder();
      _showMessage('Cảm ơn bạn đã đánh giá.');
      widget.onOrderUpdated?.call();
  }

  Future<void> _openSupportRequest() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupportRequestPage(
          userId: widget.userId,
          orderId: (_currentOrder ?? widget.order).id,
          orderCode: 'Đơn hàng #${(_currentOrder ?? widget.order).id}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = _currentOrder ?? widget.order;
    final status = _currentStatus;
    final statusText = _mapStatus(status);
    final dateText = order.orderDate != null
        ? DateFormatter.formatDate(order.orderDate!.toLocal())
        : '--/--/----';
    final addressNew = _addressNew.trim();
    final addressOld = _addressOld.trim();
    final hasAddressNew = addressNew.isNotEmpty;
    final hasAddressOld = addressOld.isNotEmpty;
    final nameText = _recipientName.trim().isNotEmpty
        ? _recipientName.trim()
        : 'Chưa có tên người nhận';
    final phoneText = _phoneNumber.trim().isNotEmpty
        ? _phoneNumber.trim()
        : 'Chưa có số điện thoại';
    final totalQty = order.items.fold<int>(
      0,
      (sum, current) => sum + current.quantity,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_addressUpdated),
        ),
        title: const Text('Thông tin đơn hàng'),
        centerTitle: false,
        toolbarHeight: 44,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.orange600, AppColors.rose500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                _StatusBanner(statusText: statusText),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Thông tin vận chuyển',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow(
                        icon: Icons.local_shipping_outlined,
                        title: status == 'delivered'
                            ? 'Giao hàng thành công'
                            : statusText,
                        subtitle: dateText,
                        accent: AppColors.teal600,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Đơn vị vận chuyển: Chưa cập nhật',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.gray600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Thông tin nhận hàng',
                  trailing: status == 'pending_confirmation'
                      ? InkWell(
                          onTap: _updatingAddress ? null : _handleChangeAddress,
                          child: Text(
                            _updatingAddress ? 'Đang cập nhật' : 'Thay đổi',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: AppColors.orange600,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Người nhận',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.gray600,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        nameText,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.gray700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Số điện thoại',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.gray600,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phoneText,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.gray700),
                      ),
                      const SizedBox(height: 8),
                      if (hasAddressNew) ...[
                        Text(
                          'Địa chỉ mới',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.gray600,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          addressNew,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.gray700),
                        ),
                      ],
                      if (hasAddressNew && hasAddressOld)
                        const SizedBox(height: 8),
                      if (hasAddressOld) ...[
                        Text(
                          'Địa chỉ cũ',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: AppColors.gray600,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          addressOld,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.gray700),
                        ),
                      ],
                      if (!hasAddressNew && !hasAddressOld)
                        Text(
                          'Chưa có địa chỉ giao hàng',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.gray600),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Sản phẩm',
                  trailing: Text(
                    'Mã đơn #${order.id}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.gray600),
                  ),
                  child: Column(
                    children: [
                      ..._buildItems(context),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Chi tiết thanh toán',
                  child: Column(
                    children: [
                      _PriceRow(
                        label: 'Tạm tính',
                        value: formatPrice(order.subtotal),
                      ),
                      _PriceRow(
                        label: 'Phí vận chuyển',
                        value: formatPrice(order.shippingFee),
                      ),
                      _PriceRow(
                        label: 'Giảm giá sản phẩm',
                        value: order.productDiscount == 0
                            ? formatPrice(0)
                            : '-${formatPrice(order.productDiscount)}',
                      ),
                      _PriceRow(
                        label: 'Giảm phí vận chuyển',
                        value: order.shippingDiscount == 0
                            ? formatPrice(0)
                            : '-${formatPrice(order.shippingDiscount)}',
                      ),
                      const Divider(height: 16, color: AppColors.gray200),
                      _PriceRow(
                        label:
                            'Tổng cộng (${totalQty > 0 ? totalQty : 1} sản phẩm)',
                        value: formatPrice(order.totalPrice),
                        isEmphasis: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildActions(status),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final order = _currentOrder ?? widget.order;
    final items = order.items;
    if (items.isEmpty) {
      return [
        Text(
          'Không có sản phẩm.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.gray600),
        ),
      ];
    }

    final visibleItems = items;
    final widgets = <Widget>[];

    for (var index = 0; index < visibleItems.length; index++) {
      final item = visibleItems[index];
      widgets.add(
        _OrderItemRow(
          title: item.bookTitle,
          quantity: item.quantity,
          price: item.price,
          originalPrice: item.bookPrice,
          imageUrl: item.bookImageUrl,
          imageSize: 68,
        ),
      );
      if (index != visibleItems.length - 1) {
        widgets.add(const SizedBox(height: 10));
      }
    }

    _expandedItems = true;

    return widgets;
  }

  Widget _buildActions(String status) {
    if (status == 'pending_confirmation') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _openSupportRequest,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange600,
                side: const BorderSide(color: AppColors.orange600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Hỗ trợ'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _cancelling ? null : _confirmCancelOrder,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange600,
                side: const BorderSide(color: AppColors.orange600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(_cancelling ? 'Đang hủy...' : 'Hủy'),
            ),
          ),
        ],
      );
    }

    if (status == 'waiting_pickup') {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _openSupportRequest,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.orange600,
            side: const BorderSide(color: AppColors.orange600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: const Text('Hỗ trợ'),
        ),
      );
    }

    if (status == 'shipping') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _openSupportRequest,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange600,
                side: const BorderSide(color: AppColors.orange600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Hỗ trợ'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _markingReceived ? null : _markOrderReceived,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child:
                  Text(_markingReceived ? 'Đang xác nhận...' : 'Đã nhận được hàng'),
            ),
          ),
        ],
      );
    }

    if (status == 'delivered') {
      if (_reviewed) {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _openSupportRequest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.orange600,
                  side: const BorderSide(color: AppColors.orange600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Hỗ trợ'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _handleBuyAgain,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Mua lại'),
              ),
            ),
          ],
        );
      }
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _openSupportRequest,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange600,
                side: const BorderSide(color: AppColors.orange600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Hỗ trợ'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _openReviewPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Đánh giá'),
            ),
          ),
        ],
      );
    }

    if (status == 'cancelled') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _openSupportRequest,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange600,
                side: const BorderSide(color: AppColors.orange600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Hỗ trợ'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                _showMessage('Mua lại sản phẩm.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Mua lại'),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleBuyAgain() async {
    final order = _currentOrder ?? widget.order;
    if (order.items.isEmpty) {
      _showMessage('Đơn hàng không có sản phẩm.');
      return;
    }

    try {
      int successCount = 0;
      // Thêm tất cả sản phẩm vào giỏ hàng
      for (final item in order.items) {
        try {
          await _cartService.addToCart(
            userId: widget.userId,
            bookId: item.bookId,
            quantity: item.quantity,
          );
          successCount++;
        } catch (e) {
          // Bỏ qua lỗi cho từng sản phẩm, tiếp tục với sản phẩm khác
          continue;
        }
      }

      if (!mounted) return;

      if (successCount == 0) {
        _showMessage('Không thể thêm sản phẩm vào giỏ hàng.');
        return;
      }

      // Hiển thị thông báo trước khi pop
      final message = successCount == order.items.length
          ? 'Đã thêm $successCount sản phẩm vào giỏ hàng'
          : 'Đã thêm $successCount/${order.items.length} sản phẩm vào giỏ hàng';

      // Hiển thị thông báo ngay lập tức
      if (mounted) {
        showTopMessage(
          context,
          message: message,
          type: TopMessageType.success,
        );
      }

      // Chuyển đến trang giỏ hàng và pop sau một chút để user thấy thông báo
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        HomePage.setActiveTab('cart');
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    } catch (e) {
      if (!mounted) return;
      _showMessage('Có lỗi xảy ra khi thêm vào giỏ hàng.');
    }
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'pending_confirmation':
        return 'Chờ xác nhận';
      case 'waiting_pickup':
        return 'Chờ lấy hàng';
      case 'shipping':
        return 'Chờ giao hàng';
      case 'delivered':
        return 'Đã giao';
      case 'cancelled':
        return 'Đã hủy';
      case 'processing':
        return 'Đang xử lý';
      default:
        return status;
    }
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.statusText});

  final String statusText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.teal600,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đơn hàng $statusText',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: accent ?? AppColors.gray600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accent ?? AppColors.gray900,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.gray600),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportRow extends StatelessWidget {
  const _SupportRow({
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gray600),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.gray600),
                ),
              ],
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: AppColors.gray400),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: AppColors.gray600);
    final valueStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w600,
          color: AppColors.gray900,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({
    required this.title,
    required this.quantity,
    required this.price,
    required this.originalPrice,
    required this.imageUrl,
    required this.imageSize,
  });

  final String title;
  final int quantity;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final double imageSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray200),
          ),
          clipBehavior: Clip.antiAlias,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image_outlined,
                    color: AppColors.gray500,
                  ),
                )
              : const Icon(
                  Icons.image_outlined,
                  color: AppColors.gray500,
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'x$quantity',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.gray600),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (originalPrice > 0)
                        Text(
                          formatPrice(originalPrice),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppColors.gray500,
                                decoration: TextDecoration.lineThrough,
                              ),
                        ),
                      Text(
                        formatPrice(price),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
