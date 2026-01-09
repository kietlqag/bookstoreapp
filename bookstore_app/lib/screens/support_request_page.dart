import 'dart:io';

import 'package:flutter/material.dart';

import '../models/support_service.dart';
import '../utils/config.dart';
import '../widgets/app_colors.dart';

class SupportRequestPage extends StatefulWidget {
  const SupportRequestPage({
    super.key,
    required this.userId,
    this.orderId,
    this.orderCode,
  });

  final int userId;
  final int? orderId;
  final String? orderCode;

  @override
  State<SupportRequestPage> createState() => _SupportRequestPageState();
}

class _SupportRequestPageState extends State<SupportRequestPage> {
  late final SupportService _supportService =
      SupportService(baseUrl: _resolveBaseUrl());
  
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  String? _selectedCategory;
  bool _submitting = false;

  static String _resolveBaseUrl() {
    return AppConfig.getBaseUrlSync();
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill nếu có orderId
    if (widget.orderId != null && widget.orderCode != null) {
      _selectedCategory = 'order';
      _subjectController.text = 'Hỗ trợ đơn hàng ${widget.orderCode}';
      _messageController.text = 'Tôi cần hỗ trợ về đơn hàng ${widget.orderCode}.\n\n';
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate() || _submitting) return;

    setState(() {
      _submitting = true;
    });

    try {
      await _supportService.submitSupportRequest(
        userId: widget.userId,
        orderId: widget.orderId,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        category: _selectedCategory,
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi yêu cầu hỗ trợ thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gửi yêu cầu thất bại. Vui lòng thử lại sau.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Gửi yêu cầu hỗ trợ'),
        centerTitle: false,
        toolbarHeight: 44,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
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
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Loại yêu cầu',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      hintText: 'Chọn loại yêu cầu',
                      filled: true,
                      fillColor: AppColors.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'order',
                        child: Text('Vấn đề đơn hàng'),
                      ),
                      DropdownMenuItem(
                        value: 'product',
                        child: Text('Vấn đề sản phẩm'),
                      ),
                      DropdownMenuItem(
                        value: 'payment',
                        child: Text('Vấn đề thanh toán'),
                      ),
                      DropdownMenuItem(
                        value: 'delivery',
                        child: Text('Vấn đề giao hàng'),
                      ),
                      DropdownMenuItem(
                        value: 'account',
                        child: Text('Vấn đề tài khoản'),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('Khác'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      labelText: 'Tiêu đề *',
                      hintText: 'Nhập tiêu đề yêu cầu',
                      filled: true,
                      fillColor: AppColors.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập tiêu đề';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Nội dung *',
                      hintText: 'Mô tả chi tiết vấn đề của bạn',
                      filled: true,
                      fillColor: AppColors.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Vui lòng nhập nội dung';
                      }
                      if (value.trim().length < 10) {
                        return 'Nội dung phải có ít nhất 10 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email (tùy chọn)',
                      hintText: 'your@email.com',
                      filled: true,
                      fillColor: AppColors.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          !value.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Số điện thoại (tùy chọn)',
                      hintText: '0123456789',
                      filled: true,
                      fillColor: AppColors.gray100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.gray200,
                  disabledForegroundColor: AppColors.gray500,
                ),
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Gửi yêu cầu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
