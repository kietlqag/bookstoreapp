import 'dart:io';

import 'package:flutter/material.dart';

import '../models/payment_method.dart';
import '../models/payment_method_service.dart';
import '../widgets/app_colors.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({
    super.key,
    this.selectedCode,
  });

  final String? selectedCode;

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String? _selectedCode;
  late final PaymentMethodService _paymentService =
      PaymentMethodService(baseUrl: _resolveBaseUrl());
  List<PaymentMethod> _methods = [];
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.selectedCode;
    _loadPaymentMethods();
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

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final methods = await _paymentService.fetchPaymentMethods();
      if (!mounted) return;
      setState(() {
        _methods = methods;
        _loading = false;
        _selectedCode ??= methods.isNotEmpty ? methods.first.code : null;
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
        title: const Text('Ph\u01b0\u01a1ng th\u1ee9c thanh to\u00e1n'),
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
                              'Kh\u00f4ng c\u00f3 ph\u01b0\u01a1ng th\u1ee9c thanh to\u00e1n.',
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
                              final selected = method.code == _selectedCode;
                              final selection = _toSelection(method);
                              return _PaymentCard(
                                method: selection,
                                selected: selected,
                                onTap: () => setState(
                                  () => _selectedCode = method.code,
                                ),
                              );
                            },
                          ),
          ),
          if (!_loading && _loadError == null && _methods.isNotEmpty)
            _BottomBar(
              selectedMethod: _toSelection(
                _methods.firstWhere(
                  (item) => item.code == _selectedCode,
                  orElse: () => _methods.first,
                ),
              ),
            ),
        ],
      ),
    );
  }

  PaymentMethodSelection _toSelection(PaymentMethod method) {
    return PaymentMethodSelection(
      id: method.id.toString(),
      code: method.code,
      title: method.title,
      provider: method.provider,
      methodType: method.methodType,
      accentColor: _resolveAccent(method.provider),
      icon: _resolveIcon(method.provider),
    );
  }

  Color _resolveAccent(String provider) {
    switch (provider) {
      case 'vnpay':
        return const Color(0xFF0062CC);
      case 'momo':
        return const Color(0xFFD61C8B);
      case 'vietqr':
        return const Color(0xFF16A34A);
      case 'cod':
        return const Color(0xFF16A34A);
      default:
        return AppColors.gray600;
    }
  }

  IconData _resolveIcon(String provider) {
    switch (provider) {
      case 'vietqr':
        return Icons.qr_code_2;
      case 'cod':
        return Icons.payments_outlined;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethodSelection method;
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: method.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                method.icon,
                color: method.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? AppColors.orange600 : AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.selectedMethod});

  final PaymentMethodSelection selectedMethod;

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
          child: const Text('Xác nhận'),
        ),
      ),
    );
  }
}

class PaymentMethodSelection {
  const PaymentMethodSelection({
    required this.id,
    required this.code,
    required this.title,
    required this.provider,
    required this.methodType,
    required this.accentColor,
    required this.icon,
  });

  final String id;
  final String code;
  final String title;
  final String provider;
  final String methodType;
  final Color accentColor;
  final IconData icon;
}
