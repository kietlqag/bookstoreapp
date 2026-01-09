import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order.dart';
import '../models/order_service.dart';
import '../models/review_service.dart';
import '../utils/config.dart';
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
    Tab(text: 'Ch\u01b0a \u0111\u00e1nh gi\u00e1'),
    Tab(text: '\u0110\u00e3 \u0111\u00e1nh gi\u00e1'),
  ];

  static String _resolveBaseUrl() {
    return AppConfig.getBaseUrlSync();
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
    final textTheme = Theme.of(context).textTheme;
    return DefaultTabController(
      length: _tabs.length,
      initialIndex: widget.initialIndex.clamp(0, _tabs.length - 1),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('\u0110\u00e1nh gi\u00e1 c\u1ee7a t\u00f4i'),
          centerTitle: false,
          toolbarHeight: 48,
          elevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
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
                        emptyLabel: 'Kh\u00f4ng c\u1ea7n \u0111\u00e1nh gi\u00e1 n\u00e0o',
                        onReview: _openReviewPage,
                      ),
                      _ReviewListTab(
                        orders: _orders,
                        filter: (order) => order.isReviewed,
                        emptyLabel: 'B\u1ea1n ch\u01b0a \u0111\u00e1nh gi\u00e1 \u0111\u01a1n n\u00e0o',
                        onReview: _openReviewPage,
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
          isEditing: order.isReviewed,
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
    this.onReview,
  });

  final List<OrderSummary> orders;
  final String emptyLabel;
  final bool Function(OrderSummary order) filter;
  final ValueChanged<OrderSummary>? onReview;

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
        final isReviewed = order.isReviewed;
        final actionLabel = isReviewed
            ? 'S\u1eeda \u0111\u00e1nh gi\u00e1'
            : '\u0110\u00e1nh gi\u00e1';
        final actionIcon = isReviewed ? Icons.edit_outlined : null;
        return _ReviewEntryCard(
          key: ValueKey('review-entry-${order.id}'),
          storeName: 'M\u00e3 \u0111\u01a1n: ${order.id}',
          items: order.items,
          actionLabel: actionLabel,
          actionIcon: actionIcon,
          onReview: onReview,
          order: order,
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: filtered.length,
    );
  }
}

class _ReviewEntryCard extends StatefulWidget {
  const _ReviewEntryCard({
    super.key,
    required this.storeName,
    required this.items,
    required this.actionLabel,
    this.actionIcon,
    this.onReview,
    this.order,
  });

  final String storeName;
  final List<OrderItemSummary> items;
  final String actionLabel;
  final IconData? actionIcon;
  final ValueChanged<OrderSummary>? onReview;
  final OrderSummary? order;

  @override
  State<_ReviewEntryCard> createState() => _ReviewEntryCardState();
}

class _ReviewEntryCardState extends State<_ReviewEntryCard> {
  bool _expanded = false;

  int _uniqueBookCount(List<OrderItemSummary> items) {
    final ids = <int>{};
    for (final item in items) {
      ids.add(item.bookId);
    }
    return ids.length;
  }

  Widget _buildItemRow(
    BuildContext context, {
    required String title,
    required String author,
    required String imageUrl,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.gray600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final hasMore = _uniqueBookCount(items) > 1;
    final shouldCollapse = hasMore && !_expanded;
    final visibleItems = shouldCollapse ? items.take(1).toList() : items;
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
            widget.storeName,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.gray700),
          ),
          const SizedBox(height: 6),
          if (visibleItems.isEmpty)
            _buildItemRow(
              context,
              title: 'S\u1ea3n ph\u1ea9m',
              author: '\u0110ang c\u1eadp nh\u1eadt',
              imageUrl: '',
            )
          else
            for (var i = 0; i < visibleItems.length; i++) ...[
              _buildItemRow(
                context,
                title: visibleItems[i].bookTitle.isNotEmpty
                    ? visibleItems[i].bookTitle
                    : 'S\u1ea3n ph\u1ea9m',
                author: visibleItems[i].bookAuthor.trim().isNotEmpty
                    ? visibleItems[i].bookAuthor.trim()
                    : '\u0110ang c\u1eadp nh\u1eadt',
                imageUrl: visibleItems[i].bookImageUrl,
              ),
              if (i < visibleItems.length - 1)
                const SizedBox(height: 10),
            ],
          if (hasMore) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.gray600,
                  textStyle: const TextStyle(fontSize: 10),
                ),
                icon: Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 14,
                ),
                label: Text(
                  _expanded ? 'Thu g\u1ecdn' : 'Xem th\u00eam',
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: widget.actionIcon != null
                    ? ElevatedButton.icon(
                        onPressed:
                            widget.order != null && widget.onReview != null
                                ? () => widget.onReview!(widget.order!)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: Icon(widget.actionIcon, size: 18),
                        label: Text(widget.actionLabel),
                      )
                    : ElevatedButton(
                        onPressed:
                            widget.order != null && widget.onReview != null
                                ? () => widget.onReview!(widget.order!)
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(widget.actionLabel),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
