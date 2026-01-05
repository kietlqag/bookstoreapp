import 'dart:io';

import 'package:flutter/material.dart';

import '../models/order.dart';
import '../models/order_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/price_formatter.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({
    super.key,
    required this.userId,
  });

  final int userId;

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  late final OrderService _orderService =
      OrderService(baseUrl: _resolveBaseUrl());
  List<OrderSummary> _orders = [];
  bool _loading = true;
  String? _loadError;

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('\u0110\u01a1n h\u00e0ng'),
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
              : _orders.isEmpty
                  ? Center(
                      child: Text(
                        'Ch\u01b0a c\u00f3 \u0111\u01a1n h\u00e0ng',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.gray600),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return _OrderCard(order: order);
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemCount: _orders.length,
                    ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    final statusText = _mapStatus(order.status);
    final dateText = order.orderDate != null
        ? '${order.orderDate!.day}/${order.orderDate!.month}/${order.orderDate!.year}'
        : '--/--/----';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'M\u00e3 \u0111\u01a1n #${order.id}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                statusText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.orange600,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ng\u00e0y \u0111\u1eb7t: $dateText',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: 8),
          Text(
            'T\u1ed5ng ti\u1ec1n: ${formatPrice(order.totalPrice)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
          ),
        ],
      ),
    );
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'pending_confirmation':
        return 'Ch\u1edd x\u00e1c nh\u1eadn';
      case 'waiting_pickup':
        return 'Ch\u1edd l\u1ea5y h\u00e0ng';
      case 'shipping':
        return '\u0110ang giao';
      case 'delivered':
        return '\u0110\u00e3 giao';
      case 'cancelled':
        return '\u0110\u00e3 h\u1ee7y';
      default:
        return status;
    }
  }
}
