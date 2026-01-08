import 'dart:io';

import 'package:flutter/material.dart';

import '../models/support_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_colors.dart';
import 'support_request_detail_page.dart';

class SupportRequestListPage extends StatefulWidget {
  const SupportRequestListPage({
    super.key,
    required this.userId,
  });

  final int userId;

  @override
  State<SupportRequestListPage> createState() => _SupportRequestListPageState();
}

class _SupportRequestListPageState extends State<SupportRequestListPage> {
  late final SupportService _supportService =
      SupportService(baseUrl: _resolveBaseUrl());

  List<SupportRequest> _requests = [];
  bool _loading = true;
  String? _error;

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
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (widget.userId <= 0) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final requests = await _supportService.fetchRequests(widget.userId);
      if (!mounted) return;
      setState(() {
        _requests = requests;
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
    return Scaffold(
      backgroundColor: AppColors.gray50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Yêu cầu hỗ trợ của tôi'),
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
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.gray400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.gray600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRequests,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.support_agent_outlined,
                              size: 64,
                              color: AppColors.gray400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có yêu cầu hỗ trợ nào',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.gray600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          return _RequestCard(
                            request: request,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SupportRequestDetailPage(
                                    requestId: request.id,
                                    userId: widget.userId,
                                  ),
                                ),
                              ).then((_) => _loadRequests());
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onTap,
  });

  final SupportRequest request;
  final VoidCallback onTap;


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.subject,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.gray900,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: request.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: request.statusColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    request.statusText,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: request.statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
            if (request.category != null && request.category!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 14,
                    color: AppColors.gray500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getCategoryText(request.category!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gray600,
                        ),
                  ),
                ],
              ),
            ],
            if (request.orderId != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 14,
                    color: AppColors.orange600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Đơn hàng #${request.orderId}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.orange600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              request.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.gray600,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppColors.gray400,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormatter.formatRelativeTime(request.createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.gray500,
                      ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.gray400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryText(String category) {
    switch (category) {
      case 'order':
        return 'Vấn đề đơn hàng';
      case 'product':
        return 'Vấn đề sản phẩm';
      case 'payment':
        return 'Vấn đề thanh toán';
      case 'delivery':
        return 'Vấn đề giao hàng';
      case 'account':
        return 'Vấn đề tài khoản';
      case 'other':
        return 'Khác';
      default:
        return category;
    }
  }
}
