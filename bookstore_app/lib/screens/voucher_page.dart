import 'dart:io';

import 'package:flutter/material.dart';

import '../models/voucher.dart';
import '../models/voucher_service.dart';
import '../utils/config.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_colors.dart';
import '../widgets/price_formatter.dart';
import '../widgets/top_message.dart';

class VoucherPage extends StatefulWidget {
  const VoucherPage({
    super.key,
    required this.orderSubtotal,
    required this.shippingFee,
    this.selectedShippingId,
    this.selectedProductId,
  });

  final double orderSubtotal;
  final double shippingFee;
  final String? selectedShippingId;
  final String? selectedProductId;

  @override
  State<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends State<VoucherPage> {
  final TextEditingController _codeController = TextEditingController();
  late final VoucherService _voucherService =
      VoucherService(baseUrl: _resolveBaseUrl());
  List<Voucher> _vouchers = [];
  String? _selectedShippingId;
  String? _selectedProductId;
  final Map<int, bool> _expanded = {};
  bool _loading = true;
  String? _loadError;
  bool _canApply = false;

  static String _resolveBaseUrl() {
    return AppConfig.getBaseUrlSync();
  }

  @override
  void initState() {
    super.initState();
    _selectedShippingId = widget.selectedShippingId;
    _selectedProductId = widget.selectedProductId;
    _codeController.addListener(_handleCodeChanged);
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final vouchers = await _voucherService.fetchVouchers();
      if (!mounted) return;
      final shippingItems = <_VoucherItem>[];
      final productItems = <_VoucherItem>[];
      for (final voucher in vouchers) {
        final item = _toVoucherItem(voucher);
        if (voucher.discountType == 'shipping') {
          shippingItems.add(item);
        } else {
          productItems.add(item);
        }
      }
      final bestShipping = _findBestItem(
        shippingItems,
        orderSubtotal: widget.orderSubtotal,
        shippingFee: widget.shippingFee,
      );
      final bestProduct = _findBestItem(
        productItems,
        orderSubtotal: widget.orderSubtotal,
        shippingFee: widget.shippingFee,
      );
      setState(() {
        _vouchers = vouchers.where((item) => item.isActive).toList();
        if (bestShipping != null) {
          _selectedShippingId = bestShipping.id;
        }
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

  void _applyCode() {
    final raw = _codeController.text.trim();
    if (raw.isEmpty) return;
    final code = raw.toUpperCase();
    final match = _vouchers.firstWhere(
      (voucher) => voucher.code.toUpperCase() == code,
      orElse: () => const Voucher(
        id: 0,
        code: '',
        title: '',
        description: null,
        discountType: '',
        discountValue: 0,
        maxDiscount: null,
        minOrderValue: 0,
        startAt: null,
        endAt: null,
        usageLimit: null,
        usedCount: 0,
        isActive: false,
      ),
    );
    if (match.id == 0) {
      showTopMessage(
        context,
        message: 'Mã voucher không tồn tại',
        type: TopMessageType.error,
      );
      return;
    }
    if (widget.orderSubtotal < match.minOrderValue) {
      showTopMessage(
        context,
        message: 'Chưa đủ điều kiện tối thiểu',
        type: TopMessageType.error,
      );
      return;
    }
    setState(() {
      if (match.discountType == 'shipping') {
        _selectedShippingId = match.id.toString();
      } else {
        _selectedProductId = match.id.toString();
      }
    });
    showTopMessage(
      context,
      message: 'Đã áp dụng ${match.code}',
      type: TopMessageType.success,
    );
  }

  List<_VoucherSection> _buildSections(
    List<Voucher> vouchers, {
    required double orderSubtotal,
    required double shippingFee,
  }) {
    final shippingItems = <_VoucherItem>[];
    final percentItems = <_VoucherItem>[];
    final amountItems = <_VoucherItem>[];

    for (final voucher in vouchers) {
      final item = _toVoucherItem(voucher);
      if (voucher.discountType == 'shipping') {
        shippingItems.add(item);
      } else if (voucher.discountType == 'percent') {
        percentItems.add(item);
      } else if (voucher.discountType == 'amount') {
        amountItems.add(item);
      }
    }

    final sections = <_VoucherSection>[];
    if (shippingItems.isNotEmpty) {
      sections.add(
        _VoucherSection(
          type: 'shipping',
          title: '\u01afu \u0111\u00e3i ph\u00ed v\u1eadn chuy\u1ec3n',
          items: _withBadges(
            shippingItems,
            orderSubtotal: orderSubtotal,
            shippingFee: shippingFee,
          ),
        ),
      );
    }
    if (percentItems.isNotEmpty) {
      sections.add(
        _VoucherSection(
          type: 'percent',
          title: 'M\u00e3 gi\u1ea3m gi\u00e1 (%)',
          items: _withBadges(
            percentItems,
            orderSubtotal: orderSubtotal,
            shippingFee: shippingFee,
          ),
        ),
      );
    }
    if (amountItems.isNotEmpty) {
      sections.add(
        _VoucherSection(
          type: 'amount',
          title: 'M\u00e3 gi\u1ea3m gi\u00e1 (ti\u1ec1n)',
          items: _withBadges(
            amountItems,
            orderSubtotal: orderSubtotal,
            shippingFee: shippingFee,
          ),
        ),
      );
    }
    return sections;
  }

  List<_VoucherItem> _withBadges(
    List<_VoucherItem> items, {
    required double orderSubtotal,
    required double shippingFee,
  }) {
    if (items.isEmpty) return items;
    final result = items.toList();
    result.sort((a, b) {
      final scoreA = _voucherScore(
        a,
        orderSubtotal: orderSubtotal,
        shippingFee: shippingFee,
      );
      final scoreB = _voucherScore(
        b,
        orderSubtotal: orderSubtotal,
        shippingFee: shippingFee,
      );
      final eligibleA = scoreA > 0;
      final eligibleB = scoreB > 0;
      if (eligibleA != eligibleB) {
        return eligibleA ? -1 : 1;
      }
      final compare = scoreB.compareTo(scoreA);
      if (compare != 0) return compare;
      return a.id.compareTo(b.id);
    });

    final best = result.isNotEmpty
        ? _voucherScore(
              result.first,
              orderSubtotal: orderSubtotal,
              shippingFee: shippingFee,
            ) >
            0
            ? result.first
            : null
        : null;

    return result
        .map(
          (item) => item.copyWith(
            badge: best != null && best.id == item.id
                ? 'L\u1ef1a ch\u1ecdn t\u1ed1t nh\u1ea5t'
                : null,
          ),
        )
        .toList();
  }

  _VoucherItem? _findBestItem(
    List<_VoucherItem> items, {
    required double orderSubtotal,
    required double shippingFee,
  }) {
    if (items.isEmpty) return null;
    final sorted = items.toList()
      ..sort((a, b) {
        final scoreA = _voucherScore(
          a,
          orderSubtotal: orderSubtotal,
          shippingFee: shippingFee,
        );
        final scoreB = _voucherScore(
          b,
          orderSubtotal: orderSubtotal,
          shippingFee: shippingFee,
        );
        final eligibleA = scoreA > 0;
        final eligibleB = scoreB > 0;
        if (eligibleA != eligibleB) {
          return eligibleA ? -1 : 1;
        }
        final compare = scoreB.compareTo(scoreA);
        if (compare != 0) return compare;
        return a.id.compareTo(b.id);
      });
    final best = sorted.first;
    return _voucherScore(
              best,
              orderSubtotal: orderSubtotal,
              shippingFee: shippingFee,
            ) >
            0
        ? best
        : null;
  }

  double _voucherScore(
    _VoucherItem item, {
    required double orderSubtotal,
    required double shippingFee,
  }) {
    return _calculateDiscount(
      item,
      orderSubtotal: orderSubtotal,
      shippingFee: shippingFee,
    );
  }

  double _calculateDiscount(
    _VoucherItem item, {
    required double orderSubtotal,
    required double shippingFee,
  }) {
    if (orderSubtotal < item.minOrderValue) {
      return 0.0;
    }
    if (item.discountType == 'shipping') {
      return item.discountValue.clamp(0.0, shippingFee);
    }
    if (item.discountType == 'percent') {
      final raw = orderSubtotal * item.discountValue / 100.0;
      final capped = item.maxDiscount != null && item.maxDiscount! > 0
          ? raw.clamp(0.0, item.maxDiscount!)
          : raw;
      return capped.clamp(0.0, orderSubtotal);
    }
    if (item.discountType == 'amount') {
      return item.discountValue.clamp(0.0, orderSubtotal);
    }
    return 0.0;
  }

  _VoucherItem _toVoucherItem(Voucher voucher) {
    final minOrder = voucher.minOrderValue;
    final subtitle = voucher.description?.trim().isNotEmpty == true
        ? voucher.description!.trim()
        : minOrder > 0
            ? '\u0110\u01a1n t\u1ed1i thi\u1ec3u ${formatPrice(minOrder)}'
            : '\u00c1p d\u1ee5ng cho \u0111\u01a1n t\u1eeb 0\u0111';

    final hasUsageLimit =
        voucher.usageLimit != null && voucher.usageLimit! > 0;
    final usedPercent = hasUsageLimit
        ? (voucher.usedCount / voucher.usageLimit!).clamp(0.0, 1.0)
        : 0.0;

    final usedLine = hasUsageLimit
        ? '\u0110\u00e3 d\u00f9ng ${(usedPercent * 100).round()}%'
        : (voucher.usedCount > 0
            ? '\u0110\u00e3 d\u00f9ng ${voucher.usedCount}'
            : null);
    final expiryLine = voucher.endAt != null
        ? 'Hết hạn ${DateFormatter.formatDateShort(voucher.endAt!)}'
        : null;
    // condition chỉ chứa usedLine hoặc mặc định, không chứa expiryLine để tránh duplicate
    final condition = usedLine ?? 'C\u00f2n hi\u1ec7u l\u1ef1c';

    final color = voucher.discountType == 'shipping'
        ? const Color(0xFF14B8A6)
        : voucher.discountType == 'percent'
            ? const Color(0xFFF97316)
            : const Color(0xFFE11D48);

    String title;
    if (voucher.discountType == 'shipping') {
      title = 'Gi\u1ea3m ph\u00ed v\u1eadn chuy\u1ec3n '
          '${formatPrice(voucher.discountValue)}';
    } else if (voucher.discountType == 'percent') {
      final percentValue = voucher.discountValue.toStringAsFixed(0);
      if (voucher.maxDiscount != null && voucher.maxDiscount! > 0) {
        title = 'Gi\u1ea3m $percentValue% t\u1ed1i \u0111a '
            '${formatPrice(voucher.maxDiscount!)}';
      } else {
        title = 'Gi\u1ea3m $percentValue%';
      }
    } else {
      title = 'Gi\u1ea3m ${formatPrice(voucher.discountValue)}';
    }

    return _VoucherItem(
      id: voucher.id.toString(),
      code: voucher.code,
      title: title,
      subtitle: subtitle,
      condition: condition,
      expiryLine: expiryLine,
      badge: null,
      usedPercent: usedPercent,
      color: color,
      isVip: false,
      minOrderValue: voucher.minOrderValue,
      discountType: voucher.discountType,
      discountValue: voucher.discountValue,
      maxDiscount: voucher.maxDiscount,
    );
  }


  @override
  void dispose() {
    _codeController.removeListener(_handleCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  void _handleCodeChanged() {
    final canApply = _codeController.text.trim().isNotEmpty;
    if (canApply == _canApply) return;
    setState(() {
      _canApply = canApply;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections(
      _vouchers,
      orderSubtotal: widget.orderSubtotal,
      shippingFee: widget.shippingFee,
    );
    final selectedShippingItem =
        _findItemById(sections, _selectedShippingId);
    final selectedProductItem = _findItemById(sections, _selectedProductId);
    final shippingDiscount = selectedShippingItem == null
        ? 0.0
        : _calculateDiscount(
            selectedShippingItem,
            orderSubtotal: widget.orderSubtotal,
            shippingFee: widget.shippingFee,
          );
    final productDiscount = selectedProductItem == null
        ? 0.0
        : _calculateDiscount(
            selectedProductItem,
            orderSubtotal: widget.orderSubtotal,
            shippingFee: widget.shippingFee,
          );
    final totalDiscount = shippingDiscount + productDiscount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ch\u1ecdn Voucher'),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      hintText: 'Nh\u1eadp m\u00e3 voucher',
                      hintStyle: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.gray600),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _canApply ? _applyCode : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _canApply ? AppColors.orange600 : AppColors.gray200,
                      foregroundColor:
                          _canApply ? Colors.white : AppColors.gray600,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('\u00c1p d\u1ee5ng',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
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
                    : sections.isEmpty
                        ? Center(
                            child: Text(
                              'Kh\u00f4ng c\u00f3 voucher ph\u00f9 h\u1ee3p.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.gray600),
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            children: [
                              for (var index = 0;
                                  index < sections.length;
                                  index++)
                                _VoucherSectionView(
                                  section: sections[index],
                                  selectedShippingId: _selectedShippingId,
                                  selectedProductId: _selectedProductId,
                                  orderSubtotal: widget.orderSubtotal,
                                  expanded: _expanded[index] ?? false,
                                  onSelected: (type, id) => setState(() {
                                    if (type == 'shipping') {
                                      _selectedShippingId = id;
                                    } else {
                                      _selectedProductId = id;
                                    }
                                  }),
                                  onToggleExpand: () => setState(
                                    () => _expanded[index] =
                                        !(_expanded[index] ?? false),
                                  ),
                                ),
                            ],
                          ),
          ),
          _BottomBar(
            totalDiscount: totalDiscount,
            onOk: () {
              Navigator.pop(
                context,
                VoucherSelectionResult(
                  shipping: selectedShippingItem == null
                      ? null
                      : VoucherSelection.fromItem(selectedShippingItem),
                  product: selectedProductItem == null
                      ? null
                      : VoucherSelection.fromItem(selectedProductItem),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  _VoucherItem? _findItemById(List<_VoucherSection> sections, String? id) {
    if (id == null) return null;
    for (final section in sections) {
      for (final item in section.items) {
        if (item.id == id) {
          return item;
        }
      }
    }
    return null;
  }
}

class _VoucherSectionView extends StatelessWidget {
  const _VoucherSectionView({
    required this.section,
    required this.selectedShippingId,
    required this.selectedProductId,
    required this.orderSubtotal,
    required this.onSelected,
    required this.expanded,
    required this.onToggleExpand,
  });

  final _VoucherSection section;
  final String? selectedShippingId;
  final String? selectedProductId;
  final double orderSubtotal;
  final void Function(String type, String id) onSelected;
  final bool expanded;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context) {
    const maxVisible = 3;
    final canExpand = section.items.length > maxVisible;
    final visibleItems =
        expanded ? section.items : section.items.take(maxVisible);
    final selectedId =
        section.type == 'shipping' ? selectedShippingId : selectedProductId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            section.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...visibleItems.map(
          (item) => _VoucherCard(
            item: item,
            selected: selectedId == item.id,
            orderSubtotal: orderSubtotal,
            onTap: () => onSelected(section.type, item.id),
          ),
        ),
        if (canExpand)
          Center(
            child: TextButton(
              onPressed: onToggleExpand,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expanded ? 'Thu g\u1ecdn' : 'Xem th\u00eam',
                    style: const TextStyle(fontSize: 10),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _VoucherCard extends StatelessWidget {
  const _VoucherCard({
    required this.item,
    required this.selected,
    required this.orderSubtotal,
    required this.onTap,
  });

  final _VoucherItem item;
  final bool selected;
  final double orderSubtotal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = orderSubtotal < item.minOrderValue;
    final showSelected = selected && !isDisabled;
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDisabled ? AppColors.gray50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDisabled ? 0.01 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TicketBadge(
              color: isDisabled ? AppColors.gray400 : item.color,
              isVip: item.isVip,
              code: item.code,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDisabled
                                        ? AppColors.gray600
                                        : AppColors.gray900,
                                  ),
                        ),
                      ),
                      if (item.badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDisabled
                                ? AppColors.gray100
                                : AppColors.orange50,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.badge!,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isDisabled
                                          ? AppColors.gray600
                                          : AppColors.orange600,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.gray600),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: item.usedPercent,
                    minHeight: 5,
                    backgroundColor: AppColors.gray200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isDisabled ? AppColors.gray400 : item.color,
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.condition,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AppColors.gray600),
                            ),
                            if (item.expiryLine != null)
                              Text(
                                item.expiryLine!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AppColors.gray600),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        isDisabled
                            ? 'Ch\u01b0a \u0111\u1ee7 t\u1ed1i thi\u1ec3u'
                            : '\u0110i\u1ec1u ki\u1ec7n',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: isDisabled
                                  ? AppColors.gray600
                                  : AppColors.teal600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              showSelected
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: showSelected ? AppColors.orange600 : AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketBadge extends StatelessWidget {
  const _TicketBadge({
    required this.color,
    required this.isVip,
    required this.code,
  });

  final Color color;
  final bool isVip;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 92,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVip ? Icons.workspace_premium : Icons.local_offer,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: 6),
          Text(
            isVip ? 'VIP' : code,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.totalDiscount,
    required this.onOk,
  });

  final double totalDiscount;
  final VoidCallback onOk;

  @override
  Widget build(BuildContext context) {
    final summaryText = totalDiscount <= 0
        ? 'Ch\u01b0a ch\u1ecdn voucher'
        : 'Gi\u1ea3m: ${formatPrice(totalDiscount)}';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            summaryText,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: onOk,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Xác nhận'),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoucherSection {
  const _VoucherSection({
    required this.type,
    required this.title,
    required this.items,
  });

  final String type;
  final String title;
  final List<_VoucherItem> items;
}

class _VoucherItem {
  const _VoucherItem({
    required this.id,
    required this.code,
    required this.title,
    required this.subtitle,
    required this.condition,
    required this.expiryLine,
    required this.badge,
    required this.usedPercent,
    required this.color,
    required this.isVip,
    required this.minOrderValue,
    required this.discountType,
    required this.discountValue,
    required this.maxDiscount,
  });

  final String id;
  final String code;
  final String title;
  final String subtitle;
  final String condition;
  final String? expiryLine;
  final String? badge;
  final double usedPercent;
  final Color color;
  final bool isVip;
  final double minOrderValue;
  final String discountType;
  final double discountValue;
  final double? maxDiscount;

  _VoucherItem copyWith({String? badge}) {
    return _VoucherItem(
      id: id,
      code: code,
      title: title,
      subtitle: subtitle,
      condition: condition,
      expiryLine: expiryLine,
      badge: badge,
      usedPercent: usedPercent,
      color: color,
      isVip: isVip,
      minOrderValue: minOrderValue,
      discountType: discountType,
      discountValue: discountValue,
      maxDiscount: maxDiscount,
    );
  }
}

class VoucherSelectionResult {
  const VoucherSelectionResult({
    this.shipping,
    this.product,
  });

  final VoucherSelection? shipping;
  final VoucherSelection? product;
}

class VoucherSelection {
  const VoucherSelection({
    required this.id,
    required this.code,
    required this.color,
    required this.discountType,
    required this.discountValue,
    required this.maxDiscount,
    required this.minOrderValue,
  });

  final String id;
  final String code;
  final Color color;
  final String discountType;
  final double discountValue;
  final double? maxDiscount;
  final double minOrderValue;

  static VoucherSelection fromItem(_VoucherItem item) {
    return VoucherSelection(
      id: item.id,
      code: item.code,
      color: item.color,
      discountType: item.discountType,
      discountValue: item.discountValue,
      maxDiscount: item.maxDiscount,
      minOrderValue: item.minOrderValue,
    );
  }
}
