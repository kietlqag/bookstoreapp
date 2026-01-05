import 'dart:io';

import 'package:flutter/material.dart';

import '../models/shipping_method.dart';
import '../models/shipping_method_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/price_formatter.dart';

class ShippingMethodPage extends StatefulWidget {
  const ShippingMethodPage({
    super.key,
    this.selectedId,
  });

  final String? selectedId;

  @override
  State<ShippingMethodPage> createState() => _ShippingMethodPageState();
}

class _ShippingMethodPageState extends State<ShippingMethodPage> {
  String? _selectedId;
  late final ShippingMethodService _shippingService =
      ShippingMethodService(baseUrl: _resolveBaseUrl());
  List<ShippingMethod> _methods = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedId;
    _loadShippingMethods();
  }

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

  Future<void> _loadShippingMethods() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final methods = await _shippingService.fetchShippingMethods();
      if (!mounted) return;
      setState(() {
        _methods = methods;
        _loading = false;
        _selectedId ??= methods.isNotEmpty ? methods.first.id.toString() : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _loading = false;
      });
    }
  }

  String _formatDateRange(DateTime start, int minDays, int maxDays) {
    if (minDays <= 0 && maxDays <= 0) {
      return 'Nhận trong thời gian sớm nhất';
    }
    final minDate = start.add(Duration(days: minDays));
    final maxDate = start.add(Duration(days: maxDays));
    if (minDays == maxDays) {
      return 'Nhận ngày ${_formatDate(minDate)}';
    }
    return 'Nhận từ ${_formatDate(minDate)} - ${_formatDate(maxDate)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day} Tháng ${date.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phương thức vận chuyển'),
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
            child: _loading
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
                    : _methods.isEmpty
                        ? Center(
                            child: Text(
                              'Không có phương thức vận chuyển.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.gray600),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                            itemCount: _methods.length,
                            itemBuilder: (context, index) {
                              final method = _methods[index];
                              final selected =
                                  method.id.toString() == _selectedId;
                              final range = _formatDateRange(
                                DateTime.now(),
                                method.minDays,
                                method.maxDays,
                              );
                              final displayName =
                                  method.subtitle?.trim().isNotEmpty == true
                                      ? method.subtitle!
                                      : method.title;
                              return _ShippingCard(
                                method: ShippingMethodSelection(
                                  id: method.id.toString(),
                                  code: method.code,
                                  title: method.title,
                                  subtitle: displayName,
                                  description: method.description,
                                  fee: method.fee,
                                  accentColor: AppColors.teal600,
                                  minDays: method.minDays,
                                  maxDays: method.maxDays,
                                ),
                                displayTitle: range,
                                displayName: displayName,
                                selected: selected,
                                onTap: () =>
                                    setState(() =>
                                        _selectedId = method.id.toString()),
                              );
                            },
                          ),
          ),
          if (!_loading && _loadError == null && _methods.isNotEmpty)
            _BottomBar(
              selectedMethod: _toSelection(
                _methods.firstWhere(
                  (item) => item.id.toString() == _selectedId,
                  orElse: () => _methods.first,
                ),
              ),
            ),
        ],
      ),
    );
  }

  ShippingMethodSelection _toSelection(ShippingMethod method) {
    final displayName = method.subtitle?.trim().isNotEmpty == true
        ? method.subtitle!
        : method.title;
    return ShippingMethodSelection(
      id: method.id.toString(),
      code: method.code,
      title: method.title,
      subtitle: displayName,
      description: method.description,
      fee: method.fee,
      accentColor: AppColors.teal600,
      minDays: method.minDays,
      maxDays: method.maxDays,
    );
  }
}

class _ShippingCard extends StatelessWidget {
  const _ShippingCard({
    required this.method,
    required this.displayTitle,
    required this.displayName,
    required this.selected,
    required this.onTap,
  });

  final ShippingMethodSelection method;
  final String displayTitle;
  final String displayName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: method.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.local_shipping,
                color: method.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayTitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: AppColors.teal600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayName,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.gray600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    method.description ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.gray600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatPrice(method.fee),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? AppColors.orange600 : AppColors.gray400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selectedMethod});

  final ShippingMethodSelection selectedMethod;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedMethod),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange600,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('OK'),
        ),
      ),
    );
  }
}

class ShippingMethodSelection {
  const ShippingMethodSelection({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.fee,
    required this.accentColor,
    required this.minDays,
    required this.maxDays,
  });

  final String id;
  final String code;
  final String title;
  final String subtitle;
  final String? description;
  final double fee;
  final Color accentColor;
  final int minDays;
  final int maxDays;
}
