import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/address.dart';
import '../models/address_service.dart';
import '../models/cart_item.dart';
import '../models/order_service.dart';
import '../models/payment_method.dart';
import '../models/payment_method_service.dart';
import '../models/payment_service.dart';
import '../models/shipping_method.dart';
import '../models/shipping_method_service.dart';
import '../models/voucher.dart';
import '../models/voucher_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/price_formatter.dart';
import '../widgets/top_message.dart';
import 'address_list_page.dart';
import 'payment_method_page.dart';
import 'shipping_method_page.dart';
import 'voucher_page.dart';
import 'order_success_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    super.key,
    required this.items,
    this.userId = 0,
    this.onOrderCompleted,
  });

  final List<CartItem> items;
  final int userId;
  final ValueChanged<List<int>>? onOrderCompleted;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final TextEditingController _noteController = TextEditingController();
  late final AddressService _addressService =
      AddressService(baseUrl: _resolveBaseUrl());
  List<Address> _addresses = [];
  Address? _selectedAddress;
  bool _loadingAddresses = false;
  VoucherSelection? _selectedShippingVoucher;
  VoucherSelection? _selectedProductVoucher;
  ShippingMethodSelection? _selectedShipping;
  PaymentMethodSelection? _selectedPaymentMethod;
  bool _processingPayment = false;
  late final PaymentService _paymentService =
      PaymentService(baseUrl: _resolveBaseUrl());
  late final OrderService _orderService =
      OrderService(baseUrl: _resolveBaseUrl());
  late final PaymentMethodService _paymentMethodService =
      PaymentMethodService(baseUrl: _resolveBaseUrl());
  late final ShippingMethodService _shippingMethodService =
      ShippingMethodService(baseUrl: _resolveBaseUrl());
  late final VoucherService _voucherService =
      VoucherService(baseUrl: _resolveBaseUrl());

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

  static List<String> _splitAddressLines(String value) {
    final parts = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length <= 1) {
      return [value.trim()];
    }
    const adminPrefixes = [
      'xã ',
      'phường ',
      'thị trấn ',
      'thị xã ',
      'thành phố ',
      'huyện ',
      'quận ',
      'tỉnh ',
      'đặc khu ',
    ];
    var adminStart = -1;
    for (var i = 0; i < parts.length; i++) {
      final lower = parts[i].toLowerCase();
      if (adminPrefixes.any(lower.startsWith)) {
        adminStart = i;
        break;
      }
    }
    if (adminStart <= 0) {
      final detail = parts.first;
      final admin = parts.skip(1).join(', ');
      return [detail, admin];
    }
    final detail = parts.take(adminStart).join(', ');
    final admin = parts.skip(adminStart).join(', ');
    return [detail, admin];
  }

  static List<Widget> _buildAddressLines({
    required String label,
    required String value,
    required BuildContext context,
    required TextStyle? labelStyle,
    required TextStyle? valueStyle,
  }) {
    final lines = _splitAddressLines(value);
    final firstLine = label.isEmpty
        ? lines.first
        : '$label ${lines.first}';
    final widgets = <Widget>[
      Text.rich(
        TextSpan(
          text: label.isEmpty ? firstLine : '$label ',
          style: labelStyle,
          children: label.isEmpty
              ? null
              : [
                  TextSpan(
                    text: lines.first,
                    style: valueStyle,
                  ),
                ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ];
    if (lines.length > 1) {
      widgets.add(Text(
        lines[1],
        style: valueStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ));
    }
    return widgets;
  }

  String _formatShippingRange(int minDays, int maxDays) {
    if (minDays <= 0 && maxDays <= 0) {
      return 'Nhận trong thời gian sớm nhất';
    }
    final now = DateTime.now();
    final minDate = now.add(Duration(days: minDays));
    final maxDate = now.add(Duration(days: maxDays));
    if (minDays == maxDays) {
      return 'Nhận ngày ${_formatShippingDate(minDate)}';
    }
    return 'Nhận từ ${_formatShippingDate(minDate)} - ${_formatShippingDate(maxDate)}';
  }

  String _formatShippingDate(DateTime date) {
    return '${date.day} Tháng ${date.month}';
  }

  double _itemPrice(CartItem item) {
    final discountRate = (item.book.discount / 100).clamp(0.0, 1.0);
    return (item.book.price * (1 - discountRate)).clamp(0.0, double.infinity);
  }

  double _currentSubtotal() {
    return widget.items.fold<double>(
      0,
      (sum, item) => sum + _itemPrice(item) * item.quantity,
    );
  }

  double _currentShippingFee() {
    if (widget.items.isEmpty) return 0.0;
    return _selectedShipping?.fee ?? 30000.0;
  }

  Future<void> _loadDefaultPaymentMethod() async {
    if (_selectedPaymentMethod != null) return;
    try {
      final methods = await _paymentMethodService.fetchPaymentMethods();
      if (!mounted || methods.isEmpty) return;
      methods.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _selectedPaymentMethod = _toPaymentSelection(methods.first);
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadDefaultShippingMethod() async {
    if (_selectedShipping != null) return;
    try {
      final methods = await _shippingMethodService.fetchShippingMethods();
      if (!mounted || methods.isEmpty) return;
      methods.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final method = methods.first;
      setState(() {
        _selectedShipping = ShippingMethodSelection(
          id: method.id.toString(),
          code: method.code,
          title: method.title,
          subtitle:
              method.subtitle?.trim().isNotEmpty == true ? method.subtitle! : method.title,
          description: method.description,
          fee: method.fee,
          accentColor: AppColors.teal600,
          minDays: method.minDays,
          maxDays: method.maxDays,
        );
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> _loadDefaultShippingVoucher() async {
    if (_selectedShippingVoucher != null) return;
    try {
      final vouchers = await _voucherService.fetchVouchers(type: 'shipping');
      if (!mounted || vouchers.isEmpty) return;
      final best = _pickBestShippingVoucher(
        vouchers,
        subtotal: _currentSubtotal(),
        shippingFee: _currentShippingFee(),
      );
      if (best == null) return;
      setState(() {
        _selectedShippingVoucher = best;
      });
    } catch (_) {
      // ignore
    }
  }

  VoucherSelection? _pickBestShippingVoucher(
    List<Voucher> vouchers, {
    required double subtotal,
    required double shippingFee,
  }) {
    final now = DateTime.now();
    VoucherSelection? bestSelection;
    var bestValue = 0.0;

    for (final voucher in vouchers) {
      if (voucher.discountType != 'shipping') continue;
      if (!voucher.isActive) continue;
      if (voucher.startAt != null && voucher.startAt!.isAfter(now)) continue;
      if (voucher.endAt != null && voucher.endAt!.isBefore(now)) continue;
      if (subtotal < voucher.minOrderValue) continue;
      final value = voucher.discountValue.clamp(0.0, shippingFee);
      if (value <= 0) continue;
      if (value > bestValue) {
        bestValue = value;
        bestSelection = VoucherSelection(
          id: voucher.id.toString(),
          code: voucher.code,
          color: AppColors.teal600,
          discountType: voucher.discountType,
          discountValue: voucher.discountValue,
          maxDiscount: voucher.maxDiscount,
          minOrderValue: voucher.minOrderValue,
        );
      }
    }
    return bestSelection;
  }

  PaymentMethodSelection _toPaymentSelection(PaymentMethod method) {
    return PaymentMethodSelection(
      id: method.id.toString(),
      code: method.code,
      title: method.title,
      provider: method.provider,
      methodType: method.methodType,
      accentColor: _resolvePaymentAccent(method.provider),
      icon: _resolvePaymentIcon(method.provider),
    );
  }

  Color _resolvePaymentAccent(String provider) {
    switch (provider) {
      case 'momo':
        return const Color(0xFFD61C8B);
      case 'vietqr':
        return const Color(0xFF16A34A);
      case 'cod':
        return const Color(0xFF16A34A);
      default:
        return AppColors.orange600;
    }
  }

  IconData _resolvePaymentIcon(String provider) {
    switch (provider) {
      case 'vietqr':
        return Icons.qr_code_2;
      case 'cod':
        return Icons.payments_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  Future<void> _handlePlaceOrder(double amount) async {
    if (_selectedPaymentMethod == null) {
      showTopMessage(
        context,
        message:
            'Vui l\u00f2ng ch\u1ecdn ph\u01b0\u01a1ng th\u1ee9c thanh to\u00e1n',
        type: TopMessageType.error,
      );
      return;
    }
    if (_selectedAddress == null) {
      showTopMessage(
        context,
        message: 'Vui l\u00f2ng ch\u1ecdn \u0111\u1ecba ch\u1ec9 giao h\u00e0ng',
        type: TopMessageType.error,
      );
      return;
    }
    if (widget.userId <= 0) {
      showTopMessage(
        context,
        message: 'Kh\u00f4ng x\u00e1c \u0111\u1ecbnh \u0111\u01b0\u1ee3c t\u00e0i kho\u1ea3n',
        type: TopMessageType.error,
      );
      return;
    }
    if (_processingPayment) return;
    setState(() => _processingPayment = true);

    final subtotal = _currentSubtotal();
    final shippingFee = _currentShippingFee();
    final discount = _calculateVoucherDiscount(
      _selectedProductVoucher,
      subtotal: subtotal,
      shippingFee: shippingFee,
    );
    final shippingDiscount = _calculateVoucherDiscount(
      _selectedShippingVoucher,
      subtotal: subtotal,
      shippingFee: shippingFee,
    );
    final total = (subtotal + shippingFee - discount - shippingDiscount)
        .clamp(0.0, double.infinity);

    final itemsPayload = widget.items
        .map(
          (item) => {
            'bookId': item.book.id,
            'quantity': item.quantity,
            'price': _itemPrice(item),
          },
        )
        .toList();
    final addressValue = _selectedAddress!.addressLineNew?.trim().isNotEmpty ==
            true
        ? _selectedAddress!.addressLineNew
        : _selectedAddress!.addressLine;
    final cartItemIds = widget.items
        .map((item) => item.id)
        .where((id) => id > 0)
        .toList();
      final orderPayload = {
        'userId': widget.userId,
        'serviceId': _selectedShipping?.id != null
            ? int.tryParse(_selectedShipping!.id)
            : null,
        'recipientName': _selectedAddress!.fullName,
        'shippingAddressNew': _selectedAddress!.addressLineNew,
        'shippingAddressOld': _selectedAddress!.addressLine,
        'phoneNumber': _selectedAddress!.phoneNumber,
        'note': _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        'subtotal': subtotal,
        'shippingFee': shippingFee,
        'productDiscount': discount,
        'shippingDiscount': shippingDiscount,
        'totalPrice': total,
        'cartItemIds': cartItemIds,
        'shippingVoucherId': _selectedShippingVoucher?.id,
        'productVoucherId': _selectedProductVoucher?.id,
        'items': itemsPayload,
      };

    try {
      if (_selectedPaymentMethod!.provider == 'cod') {
        final response = await _paymentService.initiatePayment(
          methodCode: _selectedPaymentMethod!.code,
          amount: amount,
          orderPayload: orderPayload,
        );
        if (!mounted) return;
        if (response.orderId != null && response.orderId! > 0) {
          if (cartItemIds.isNotEmpty) {
            widget.onOrderCompleted?.call(cartItemIds);
          }
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderSuccessPage(
                userId: widget.userId,
                orderId: response.orderId,
                items: widget.items,
                subtotal: subtotal,
                shippingFee: shippingFee,
                productDiscount: discount,
                shippingDiscount: shippingDiscount,
                total: total,
                shippingAddressNew: _selectedAddress!.addressLineNew,
                shippingAddressOld: _selectedAddress!.addressLine,
                phoneNumber: _selectedAddress!.phoneNumber,
                paymentLabel: _selectedPaymentMethod?.title,
              ),
            ),
          );
        } else {
          showTopMessage(
            context,
            message: 'Kh\u00f4ng th\u1ec3 t\u1ea1o \u0111\u01a1n COD',
            type: TopMessageType.error,
          );
        }
        return;
      }

      final response = await _paymentService.initiatePayment(
        methodCode: _selectedPaymentMethod!.code,
        amount: amount,
        orderPayload: orderPayload,
      );
      if (!mounted) return;
      if ((response.paymentUrl != null && response.paymentUrl!.isNotEmpty) ||
          (response.qrCodeUrl != null && response.qrCodeUrl!.isNotEmpty) ||
          (response.deeplink != null && response.deeplink!.isNotEmpty)) {
        final url = response.paymentUrl?.isNotEmpty == true
            ? response.paymentUrl!
            : response.qrCodeUrl?.isNotEmpty == true
                ? response.qrCodeUrl!
                : response.deeplink!;
        debugPrint('[Payment] payUrl: $url');
        final opened = await _openPaymentUrl(url);
        debugPrint('[Payment] launchUrl opened=$opened');
        if (!opened) {
          showTopMessage(
            context,
            message:
                'Kh\u00f4ng m\u1edf \u0111\u01b0\u1ee3c trang thanh to\u00e1n',
            type: TopMessageType.error,
          );
        }
        if (response.provider == 'momo' &&
            response.txnRef != null &&
            response.txnRef!.isNotEmpty) {
          await _showPaymentPendingSheet(
            txnRef: response.txnRef!,
            paymentUrl: url,
            subtotal: subtotal,
            shippingFee: shippingFee,
            discount: discount,
            shippingDiscount: shippingDiscount,
            total: total,
            cartItemIds: cartItemIds,
          );
        }
      } else if (response.qrImageUrl != null &&
          response.qrImageUrl!.isNotEmpty) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => _QrSheet(
            qrImageUrl: response.qrImageUrl!,
            amount: amount,
          ),
        );
      } else {
        showTopMessage(
          context,
          message:
              'Kh\u00f4ng nh\u1eadn \u0111\u01b0\u1ee3c th\u00f4ng tin thanh to\u00e1n',
          type: TopMessageType.error,
        );
      }
    } catch (error) {
      if (!mounted) return;
      showTopMessage(
        context,
        message: 'Kh\u00f4ng th\u1ec3 t\u1ea1o thanh to\u00e1n',
        type: TopMessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _processingPayment = false);
      }
    }
  }

  Future<void> _showPaymentPendingSheet({
    required String txnRef,
    required String paymentUrl,
    required double subtotal,
    required double shippingFee,
    required double discount,
    required double shippingDiscount,
    required double total,
    required List<int> cartItemIds,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PaymentPendingSheet(
        onOpenAgain: () async {
          await _openPaymentUrl(paymentUrl);
        },
        onConfirm: () async {
          try {
            final status = await _paymentService.fetchPaymentStatus(txnRef);
            if (!mounted) return;
            if (status.status != 'succeeded' || status.orderId == null) {
              showTopMessage(
                context,
                message: 'Ch\u01b0a nh\u1eadn \u0111\u01b0\u1ee3c thanh to\u00e1n',
                type: TopMessageType.error,
              );
              return;
            }
            if (cartItemIds.isNotEmpty) {
              widget.onOrderCompleted?.call(cartItemIds);
            }
            Navigator.of(context).pop();
            if (!mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => OrderSuccessPage(
                  userId: widget.userId,
                  orderId: status.orderId,
                  items: widget.items,
                  subtotal: subtotal,
                  shippingFee: shippingFee,
                  productDiscount: discount,
                  shippingDiscount: shippingDiscount,
                  total: total,
                  shippingAddressNew: _selectedAddress?.addressLineNew,
                  shippingAddressOld: _selectedAddress?.addressLine,
                  phoneNumber: _selectedAddress?.phoneNumber,
                  paymentLabel: _selectedPaymentMethod?.title,
                ),
              ),
            );
          } catch (_) {
            if (!mounted) return;
            showTopMessage(
              context,
              message: 'Kh\u00f4ng ki\u1ec3m tra \u0111\u01b0\u1ee3c thanh to\u00e1n',
              type: TopMessageType.error,
            );
          }
        },
      ),
    );
  }

  Future<bool> _openPaymentUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      final opened =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      return opened;
    } catch (error) {
      debugPrint('[Payment] launchUrl error: $error');
      return false;
    }
  }

  double _calculateVoucherDiscount(
    VoucherSelection? selection, {
    required double subtotal,
    required double shippingFee,
  }) {
    if (selection == null || subtotal < selection.minOrderValue) {
      return 0.0;
    }
    if (selection.discountType == 'shipping') {
      return selection.discountValue.clamp(0.0, shippingFee);
    }
    if (selection.discountType == 'percent') {
      final raw = subtotal * selection.discountValue / 100.0;
      final capped = selection.maxDiscount != null && selection.maxDiscount! > 0
          ? raw.clamp(0.0, selection.maxDiscount!)
          : raw;
      return capped.clamp(0.0, subtotal);
    }
    if (selection.discountType == 'amount') {
      return selection.discountValue.clamp(0.0, subtotal);
    }
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _loadAddresses();
    _loadDefaultPaymentMethod();
    _loadDefaultShippingMethod();
    _loadDefaultShippingVoucher();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    if (widget.userId <= 0) return;
    setState(() {
      _loadingAddresses = true;
    });
    try {
      final addresses = await _addressService.fetchAddresses(widget.userId);
      if (!mounted) return;
      setState(() {
        _addresses = addresses;
        _selectedAddress = _addresses.firstWhere(
          (address) => address.isDefault,
          orElse: () => _addresses.isNotEmpty ? _addresses.first : Address(
            id: 0,
            fullName: '',
            phoneNumber: '',
            addressLine: '',
          ),
        );
        if (_selectedAddress?.id == 0) {
          _selectedAddress = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _addresses = [];
        _selectedAddress = null;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loadingAddresses = false;
      });
    }
  }

  Future<void> _openAddressList() async {
    final selection = await Navigator.push<AddressSelection>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressListPage(
          addresses: _addresses,
          selectedAddressId: _selectedAddress?.id ?? 0,
          userId: widget.userId,
        ),
      ),
    );
    await _loadAddresses();
    if (selection == null || !mounted) return;
    final matched = _addresses.firstWhere(
      (item) => item.id == selection.address.id,
      orElse: () => const Address(
        id: 0,
        fullName: '',
        phoneNumber: '',
        addressLine: '',
      ),
    );
    if (matched.id == 0) return;
    setState(() {
      if (selection.setAsDefault) {
        _setDefaultAddress(matched.id);
      }
      _selectedAddress = matched;
    });
  }

  void _setDefaultAddress(int addressId) {
    _addresses = _addresses
        .map(
          (address) =>
              address.copyWith(isDefault: address.id == addressId),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final subtotal = items.fold<double>(
      0,
      (sum, item) => sum + _itemPrice(item) * item.quantity,
    );
    final shippingFee = items.isEmpty
        ? 0.0
        : (_selectedShipping?.fee ?? 30000.0);
    final discount = _calculateVoucherDiscount(
      _selectedProductVoucher,
      subtotal: subtotal,
      shippingFee: shippingFee,
    );
    final shippingDiscount = _calculateVoucherDiscount(
      _selectedShippingVoucher,
      subtotal: subtotal,
      shippingFee: shippingFee,
    );
    final totalDiscount = discount + shippingDiscount;
    final total = (subtotal + shippingFee - totalDiscount)
        .clamp(0.0, double.infinity);
    final selectedAddress = _selectedAddress;
    final shippingMinDays = _selectedShipping?.minDays ?? 5;
    final shippingMaxDays = _selectedShipping?.maxDays ?? 6;
    final shippingRange = _formatShippingRange(shippingMinDays, shippingMaxDays);
    final shippingName =
        _selectedShipping?.subtitle ?? 'Giao hàng tiêu chuẩn';
    final shippingDescription = _selectedShipping?.description ??
        'Nhận voucher trị giá 15.000đ nếu đơn hàng được giao đến bạn sau ngày 8 Tháng 1 2026.';

    final voucherAccent = AppColors.orange600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán'),
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
      body: items.isEmpty
          ? Center(
              child: Text(
                'Chưa có sản phẩm để thanh toán.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppColors.gray600),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                                _SectionCard(
                  title: '',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loadingAddresses)
                        Text(
                          'Đang tải địa chỉ...',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.gray600),
                        )
                      else if (selectedAddress == null)
                        Text(
                          'Chưa có địa chỉ nhận hàng.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.gray600),
                        )
                      else ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.orange600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${selectedAddress.fullName} | '
                                '${selectedAddress.phoneNumber}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: _openAddressList,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(fontSize: 11),
                              ),
                              child: const Text('Thay \u0111\u1ed5i'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (selectedAddress.addressLineNew != null &&
                            selectedAddress.addressLineNew!.isNotEmpty) ...[
                          ..._buildAddressLines(
                            label: 'Mới:',
                            value: selectedAddress.addressLineNew!,
                            context: context,
                            labelStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.gray700,
                                  fontWeight: FontWeight.w600,
                                ),
                            valueStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.gray700,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                          const SizedBox(height: 4),
                          ..._buildAddressLines(
                            label: 'Cũ:',
                            value: selectedAddress.addressLine,
                            context: context,
                            labelStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.gray600,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                            valueStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.gray600,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                ),
                          ),
                        ] else ...[
                          ..._buildAddressLines(
                            label: '',
                            value: selectedAddress.addressLine,
                            context: context,
                            labelStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.gray600),
                            valueStyle: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.gray600),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                      if (!_loadingAddresses && selectedAddress == null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _openAddressList,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(fontSize: 11),
                            ),
                            child: const Text('Thay \u0111\u1ed5i'),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Sản phẩm',
                  child: Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    item.book.cover,
                                    width: 64,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 64,
                                      height: 84,
                                      color: AppColors.gray100,
                                      alignment: Alignment.center,
                            child: Icon(
                                        Icons.menu_book,
                                        color: AppColors.gray600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.book.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.book.author,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: AppColors.gray600),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                formatPrice(_itemPrice(item)),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelLarge
                                                    ?.copyWith(
                                                      color:
                                                          AppColors.orange600,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                              if (item.book.discount > 0)
                                                Text(
                                                  formatPrice(item.book.price),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            AppColors.gray600,
                                                        fontSize: 10,
                                                        decoration: TextDecoration
                                                            .lineThrough,
                                                      ),
                                                ),
                                            ],
                                          ),
                                          Text(
                                            'x${item.quantity}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                    color: AppColors.gray600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final selection = await Navigator.of(context)
                        .push<ShippingMethodSelection?>(
                      MaterialPageRoute<ShippingMethodSelection?>(
                        builder: (_) => ShippingMethodPage(
                          selectedId: _selectedShipping?.id,
                        ),
                      ),
                    );
                    if (!mounted) return;
                    if (selection != null) {
                      setState(() => _selectedShipping = selection);
                    }
                  },
                  child: _SectionCard(
                    title: 'Ph\u01b0\u01a1ng th\u1ee9c v\u1eadn chuy\u1ec3n',
                    trailing: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xem t\u1ea5t c\u1ea3',
                          style: TextStyle(fontSize: 10),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.local_shipping,
                              size: 18,
                              color: AppColors.teal600,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                shippingRange,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.teal600,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Text(
                              formatPrice(shippingFee),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          shippingName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shippingDescription,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.gray600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: '',
                  child: InkWell(
                    onTap: () async {
                      final selection = await Navigator.of(context)
                          .push<VoucherSelectionResult?>(
                        MaterialPageRoute<VoucherSelectionResult?>(
                          builder: (_) => VoucherPage(
                            orderSubtotal: subtotal,
                            shippingFee: shippingFee,
                            selectedShippingId:
                                _selectedShippingVoucher?.id,
                            selectedProductId: _selectedProductVoucher?.id,
                          ),
                        ),
                      );
                      if (!mounted || selection == null) return;
                      setState(() {
                        _selectedShippingVoucher = selection.shipping;
                        _selectedProductVoucher = selection.product;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gray50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: voucherAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.local_offer,
                              size: 16,
                              color: voucherAccent,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Voucher',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: voucherAccent,
                              ),
                              borderRadius: BorderRadius.circular(6),
                              color: voucherAccent.withOpacity(0.15),
                            ),
                            child: Text(
                              totalDiscount == 0
                                  ? 'Ch\u1ecdn m\u00e3'
                                  : 'Gi\u1ea3m: ${formatPrice(totalDiscount)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: voucherAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppColors.gray400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Phương thức thanh toán',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _selectedPaymentMethod?.icon ??
                                Icons.payments_outlined,
                            size: 18,
                            color: _selectedPaymentMethod?.accentColor ??
                                AppColors.orange600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedPaymentMethod?.title ?? 'Ch\u1ecdn ph\u01b0\u01a1ng th\u1ee9c thanh to\u00e1n',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () async {
                          final selection = await Navigator.of(context)
                              .push<PaymentMethodSelection?>(
                            MaterialPageRoute<PaymentMethodSelection?>(
                              builder: (_) => PaymentMethodPage(
                                selectedCode: _selectedPaymentMethod?.code,
                              ),
                            ),
                          );
                          if (!mounted || selection == null) return;
                          setState(() => _selectedPaymentMethod = selection);
                        },
                        style: TextButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Thay \u0111\u1ed5i'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Thanh toán',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RowItem(
                        label: 'Tạm tính',
                        value: formatPrice(subtotal),
                      ),
                      const SizedBox(height: 6),
                      _RowItem(
                        label: 'Phí vận chuyển',
                        value: formatPrice(shippingFee),
                      ),
                      const SizedBox(height: 6),
                      _RowItem(
                        label: 'Giảm giá sản phẩm',
                        value: discount == 0
                            ? formatPrice(0.0)
                            : '-${formatPrice(discount)}',
                        valueColor: discount == 0
                            ? AppColors.gray600
                            : AppColors.rose500,
                      ),
                      const SizedBox(height: 6),
                      _RowItem(
                        label: 'Giảm giá vận chuyển',
                        value: shippingDiscount == 0
                            ? formatPrice(0.0)
                            : '-${formatPrice(shippingDiscount)}',
                        valueColor: shippingDiscount == 0
                            ? AppColors.gray600
                            : AppColors.rose500,
                      ),
                      const Divider(height: 20, color: AppColors.gray200),
                      _RowItem(
                        label: 'Tổng thanh toán',
                        value: formatPrice(total),
                        valueColor: AppColors.gray900,
                        isEmphasis: true,
                      ),
                      const SizedBox(height: 12),
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.gray600),
                          children: const [
                            TextSpan(
                              text: 'Nhấn \'Đặt hàng\' đồng nghĩa với việc bạn ',
                            ),
                            TextSpan(text: 'đồng ý tuân theo '),
                            TextSpan(
                              text: 'Điều khoản K-Book',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.gray200)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tổng cộng',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.gray600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatPrice(total),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tiết kiệm ${formatPrice(totalDiscount)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: totalDiscount == 0
                                ? AppColors.gray600
                                : AppColors.rose500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _processingPayment ? null : () => _handlePlaceOrder(total),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('\u0110\u1eb7t h\u00e0ng'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final showHeader = title.trim().isNotEmpty || trailing != null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _RowItem extends StatelessWidget {
  const _RowItem({
    required this.label,
    required this.value,
    this.valueColor,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall;
    final valueStyle = baseStyle?.copyWith(
      fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w600,
      color: valueColor ?? AppColors.gray900,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: baseStyle?.copyWith(color: AppColors.gray600),
        ),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class _QrSheet extends StatelessWidget {
  const _QrSheet({
    required this.qrImageUrl,
    required this.amount,
  });

  final String qrImageUrl;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Qu\u00e9t m\u00e3 VietQR',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Image.network(
                  qrImageUrl,
                  height: 220,
                  width: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.qr_code_2,
                    size: 120,
                    color: AppColors.gray400,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'S\u1ed1 ti\u1ec1n: ${formatPrice(amount)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.gray700,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('T\u00f4i \u0111\u00e3 qu\u00e9t'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentPendingSheet extends StatelessWidget {
  const _PaymentPendingSheet({
    required this.onOpenAgain,
    required this.onConfirm,
  });

  final Future<void> Function() onOpenAgain;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ch\u1edd x\u00e1c nh\u1eadn thanh to\u00e1n',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sau khi thanh to\u00e1n tr\u00ean web, nh\u1ea5n "\u0110\u00e3 thanh to\u00e1n" \u0111\u1ec3 ki\u1ec3m tra \u0111\u01a1n h\u00e0ng.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.gray600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async => onOpenAgain(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange600,
                    side: const BorderSide(color: AppColors.orange600),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('M\u1edf l\u1ea1i'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async => onConfirm(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('\u0110\u00e3 thanh to\u00e1n'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}





























