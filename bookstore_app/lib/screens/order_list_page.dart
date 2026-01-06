import 'dart:io';

import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/order_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/price_formatter.dart';
import 'order_detail_page.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({
    super.key,
    required this.userId,
    this.initialTabIndex = 0,
  });

  final int userId;
  final int initialTabIndex;

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  late final OrderService _orderService =
      OrderService(baseUrl: _resolveBaseUrl());
  List<OrderSummary> _orders = [];
  bool _loading = true;
  String? _loadError;

  final List<_OrderTab> _tabs = const [
    _OrderTab(
      label: 'Chờ xác nhận',
      statuses: ['pending_confirmation'],
      showCancel: true,
    ),
    _OrderTab(
      label: 'Chờ lấy hàng',
      statuses: ['waiting_pickup'],
    ),
    _OrderTab(
      label: 'Chờ giao hàng',
      statuses: ['shipping'],
    ),
    _OrderTab(
      label: 'Đã giao',
      statuses: ['delivered'],
      showReviewRefund: true,
    ),
    _OrderTab(
      label: 'Đã hủy',
      statuses: ['cancelled'],
    ),
  ];

  static String _resolveBaseUrl() {
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) {
      return overrideUrl;
    }
    if (Platform.isAndroid) {
      return 'http://192.168.1.4:8080';
    }
    return 'http://localhost:8080';
  }

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final orders = await _orderService.fetchOrders(widget.userId);
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      initialIndex: widget.initialTabIndex.clamp(0, _tabs.length - 1),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đơn đã mua'),
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
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            padding: EdgeInsets.zero,
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            labelStyle: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            tabs: _tabs.map((tab) => Tab(text: tab.label)).toList(),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? Center(
                    child: Text(
                      _loadError!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.gray600),
                    ),
                  )
                : TabBarView(
                    children: _tabs
                        .map((tab) => _OrderTabBody(
                              tab: tab,
                              orders: _orders,
                              userId: widget.userId,
                              onRefresh: _loadOrders,
                            ))
                        .toList(),
                  ),
      ),
    );
  }
}

class _OrderTabBody extends StatelessWidget {
  const _OrderTabBody({
    required this.tab,
    required this.orders,
    required this.userId,
    required this.onRefresh,
  });

  final _OrderTab tab;
  final List<OrderSummary> orders;
  final int userId;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final filtered = tab.statuses.isEmpty
        ? orders
        : orders.where((order) => tab.statuses.contains(order.status)).toList();

    if (filtered.isEmpty) {
      return Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Chưa có đơn ở mục này',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.gray600),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemBuilder: (context, index) {
        final order = filtered[index];
        return _OrderCard(
          order: order,
          userId: userId,
          onRefresh: onRefresh,
          showCancel: tab.showCancel && order.status == 'pending_confirmation',
          showReviewRefund: tab.showReviewRefund && order.status == 'delivered',
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: filtered.length,
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({
    required this.order,
    required this.userId,
    required this.onRefresh,
    required this.showCancel,
    required this.showReviewRefund,
  });

  final OrderSummary order;
  final int userId;
  final VoidCallback onRefresh;
  final bool showCancel;
  final bool showReviewRefund;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final statusText = _mapStatus(order.status);
    final dateText = order.orderDate != null
        ? '${order.orderDate!.day}/${order.orderDate!.month}/${order.orderDate!.year}'
        : '--/--/----';
    final item = order.items.isNotEmpty ? order.items.first : null;
    final itemTitle = item?.bookTitle.isNotEmpty == true
        ? item!.bookTitle
        : 'Sản phẩm';
    final itemQty = item?.quantity ?? 0;
    final itemPrice = item?.price ?? 0;
    final itemOriginal = item?.bookPrice ?? 0;
    final totalQty = order.items.fold<int>(
      0,
      (sum, current) => sum + current.quantity,
    );
    final distinctCount = order.items
        .map((current) => current.bookId)
        .where((id) => id > 0)
        .toSet()
        .length;
    final showViewMore = distinctCount >= 2 && order.items.length > 1;

    return InkWell(
      onTap: () async {
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute<bool>(
            builder: (_) => OrderDetailPage(order: order, userId: widget.userId),
          ),
        );
        if (updated == true) {
          widget.onRefresh();
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã đơn #${order.id}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ngày đặt: $dateText',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.gray600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    statusText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.orange600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _OrderItemRow(
              title: itemTitle,
              quantity: itemQty,
              price: itemPrice,
              originalPrice: itemOriginal,
              imageUrl: item?.bookImageUrl ?? '',
              imageSize: 68,
              titleStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
              showOriginalAlways: false,
            ),
            if (_expanded)
              ...order.items
                  .skip(1)
                  .map((extraItem) => Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _OrderItemRow(
                          title: extraItem.bookTitle,
                          quantity: extraItem.quantity,
                          price: extraItem.price,
                          originalPrice: extraItem.bookPrice,
                          imageUrl: extraItem.bookImageUrl,
                          imageSize: 68,
                          titleStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          showOriginalAlways: true,
                        ),
                      )),
            if (showViewMore)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Center(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _expanded ? 'Thu gọn' : 'Xem thêm',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: AppColors.gray600,
                                  ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 14,
                          color: AppColors.gray600,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng số tiền (${totalQty > 0 ? totalQty : 1} sản phẩm):',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.gray600),
                ),
                Text(
                  formatPrice(order.totalPrice),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
      case 'returning':
        return 'Trả hàng';
      case 'refunding':
        return 'Hoàn tiền';
      case 'cancelled':
        return 'Đã hủy';
      default:
        return status;
    }
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
    required this.titleStyle,
    required this.showOriginalAlways,
  });

  final String title;
  final int quantity;
  final double price;
  final double originalPrice;
  final String imageUrl;
  final double imageSize;
  final TextStyle? titleStyle;
  final bool showOriginalAlways;

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
                style: titleStyle,
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
                      if ((showOriginalAlways && (originalPrice > 0 || price > 0)) ||
                          (originalPrice > price && originalPrice > 0))
                        Text(
                          formatPrice(
                            showOriginalAlways
                                ? (originalPrice > 0 ? originalPrice : price)
                                : originalPrice,
                          ),
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

class _OrderTab {
  const _OrderTab({
    required this.label,
    required this.statuses,
    this.showCancel = false,
    this.showReviewRefund = false,
  });

  final String label;
  final List<String> statuses;
  final bool showCancel;
  final bool showReviewRefund;
}



