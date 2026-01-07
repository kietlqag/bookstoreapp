import 'dart:io';

import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/order_service.dart';
import '../models/review_service.dart';
import '../widgets/app_colors.dart';
import 'review_order_page.dart';

class ReviewListPage extends StatefulWidget {
  const ReviewListPage({
    super.key,
    required this.userId,
    this.initialIndex = 0,
  });

  final int userId;
  final int initialIndex;

  @override
  State<ReviewListPage> createState() => _ReviewListPageState();
}

class _ReviewListPageState extends State<ReviewListPage> {
  late final OrderService _orderService =
      OrderService(baseUrl: _resolveBaseUrl());
  late final ReviewService _reviewService =
      ReviewService(baseUrl: _resolveBaseUrl());

  List<OrderSummary> _orders = [];
  bool _loading = true;
  String? _error;

  final List<Tab> _tabs = const [
    Tab(text: 'Chưa đánh giá'),
    Tab(text: 'Đã đánh giá'),
    Tab(text: 'Đánh giá người bán'),
  ];

  static String _resolveBaseUrl() {
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) return overrideUrl;
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
      _error = null;
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
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      initialIndex: widget.initialIndex.clamp(0, _tabs.length - 1),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Đánh giá của tôi'),
          centerTitle: false,
          toolbarHeight: 48,
          elevation: 0,
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
            tabs: _tabs,
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.gray600),
                    ),
                  )
                : TabBarView(
                    children: [
                      _ReviewListTab(
                        orders: _orders,
                        filter: (order) => !order.isReviewed,
                        emptyLabel: 'Không còn đánh giá nào',
                        onReview: _openReviewPage,
                        countdownLabel: 'Chỉ còn',
                        showCountdown: true,
                      ),
                      _ReviewListTab(
                        orders: _orders,
                        filter: (order) => order.isReviewed,
                        emptyLabel: 'Bạn chưa đánh giá đơn nào',
                        onReview: null,
                        countdownLabel: 'Đã đánh giá',
                        showCountdown: false,
                      ),
                      _ReviewListTab(
                        orders: _orders,
                        filter: (order) => order.isReviewed,
                        emptyLabel: 'Chưa có đánh giá người bán',
                        onReview: null,
                        countdownLabel: 'Đã đánh giá',
                        showCountdown: false,
                      ),
                    ],
                  ),
      ),
    );
  }

  Future<void> _openReviewPage(OrderSummary order) async {
    final remaining = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReviewOrderPage(
          order: order,
          userId: widget.userId,
          reviewService: _reviewService,
        ),
      ),
    );
    if (remaining == true) {
      _loadOrders();
    }
  }
}


class _ReviewListTab extends StatelessWidget {
  const _ReviewListTab({
    required this.orders,
    required this.filter,
    required this.emptyLabel,
    required this.countdownLabel,
    required this.showCountdown,
    this.onReview,
  });

  final List<OrderSummary> orders;
  final String emptyLabel;
  final String countdownLabel;
  final bool Function(OrderSummary order) filter;
  final ValueChanged<OrderSummary>? onReview;
  final bool showCountdown;

  @override
  Widget build(BuildContext context) {
    final filtered = orders.where(filter).toList();
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          emptyLabel,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.gray600),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemBuilder: (context, index) {
        final order = filtered[index];
        final item = order.items.isNotEmpty ? order.items.first : null;
        final daysLeft = _calcDaysLeft(order.orderDate);
        final reward = 200 + (item != null ? (item.quantity * 50) : 0);
        return _ReviewEntryCard(
          orderId: order.id,
          storeName: 'Shop #${order.id}',
          productTitle: item?.bookTitle ?? 'Sản phẩm',
          imageUrl: item?.bookImageUrl ?? '',
          countdownLabel: showCountdown
              ? '$countdownLabel $daysLeft ngày để đánh giá'
              : countdownLabel,
          rewardLabel: 'Đánh giá +$reward',
          onReview: onReview,
          order: order,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: filtered.length,
    );
  }

  int _calcDaysLeft(DateTime? date) {
    if (date == null) return 0;
    final elapsed = DateTime.now().difference(date).inDays;
    final left = 30 - elapsed;
    return left > 0 ? left : 0;
  }
}

class _ReviewEntryCard extends StatelessWidget {
  const _ReviewEntryCard({
    required this.orderId,
    required this.storeName,
    required this.productTitle,
    required this.imageUrl,
    required this.countdownLabel,
    required this.rewardLabel,
    this.onReview,
    this.order,
  });

  final int orderId;
  final String storeName;
  final String productTitle;
  final String imageUrl;
  final String countdownLabel;
  final String rewardLabel;
  final ValueChanged<OrderSummary>? onReview;
  final OrderSummary? order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            storeName,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.gray700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.gray200),
                  color: AppColors.gray100,
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
                child: Text(
                  productTitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            countdownLabel,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: order != null && onReview != null
                      ? () => onReview!(order!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(rewardLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
