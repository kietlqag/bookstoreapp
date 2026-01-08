import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/support_service.dart';
import '../utils/date_formatter.dart';
import '../widgets/app_colors.dart';

class SupportRequestDetailPage extends StatefulWidget {
  const SupportRequestDetailPage({
    super.key,
    required this.requestId,
    required this.userId,
  });

  final int requestId;
  final int userId;

  @override
  State<SupportRequestDetailPage> createState() =>
      _SupportRequestDetailPageState();
}

class _SupportRequestDetailPageState extends State<SupportRequestDetailPage> {
  late final SupportService _supportService =
      SupportService(baseUrl: _resolveBaseUrl());

  SupportRequestDetail? _request;
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
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    if (widget.userId <= 0) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final request = await _supportService.fetchRequestDetail(
        widget.requestId,
        widget.userId,
      );
      if (!mounted) return;
      setState(() {
        _request = request;
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
        title: const Text('Chi tiết yêu cầu'),
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
      body: _loading
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
                        onPressed: _loadRequest,
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                )
              : _request == null
                  ? const Center(child: Text('Không tìm thấy yêu cầu'))
                  : RefreshIndicator(
                      onRefresh: _loadRequest,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (_request!.orderSummary != null) ...[
                            _OrderSummaryCard(
                              orderId: _request!.orderId!,
                              orderSummary: _request!.orderSummary!,
                            ),
                            const SizedBox(height: 16),
                          ],
                          _RequestInfoCard(request: _request!),
                          const SizedBox(height: 16),
                          _StatusTimelineCard(request: _request!),
                          if (_request!.messages.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _MessagesCard(messages: _request!.messages),
                          ],
                        ],
                      ),
                    ),
    );
  }
}

class _RequestInfoCard extends StatelessWidget {
  const _RequestInfoCard({required this.request});

  final SupportRequestDetail request;

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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gray900,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
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
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: request.statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          if (request.category != null && request.category!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.category_outlined,
                  size: 18,
                  color: AppColors.gray500,
                ),
                const SizedBox(width: 8),
                Text(
                  _getCategoryText(request.category!),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray600,
                      ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Nội dung yêu cầu:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            request.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray900,
                ),
          ),
          if (request.email != null || request.phone != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            if (request.email != null)
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: request.email!,
              ),
            if (request.phone != null) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Số điện thoại',
                value: request.phone!,
              ),
            ],
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.access_time,
            label: 'Ngày gửi',
            value: DateFormatter.formatDateTime(request.createdAt),
          ),
          if (request.updatedAt != null) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.update,
              label: 'Cập nhật lần cuối',
              value: DateFormatter.formatDateTime(request.updatedAt!),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gray500),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.gray600,
                fontWeight: FontWeight.w600,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gray700,
                ),
          ),
        ),
      ],
    );
  }
}

class _StatusTimelineCard extends StatelessWidget {
  const _StatusTimelineCard({required this.request});

  final SupportRequestDetail request;

  @override
  Widget build(BuildContext context) {
    final statuses = [
      _StatusItem(
        label: 'Đã tạo yêu cầu',
        isActive: true,
        date: request.createdAt,
      ),
      _StatusItem(
        label: 'Đang xử lý',
        isActive: request.status == 'in_progress' ||
            request.status == 'resolved' ||
            request.status == 'closed',
        date: request.status == 'in_progress' ||
                request.status == 'resolved' ||
                request.status == 'closed'
            ? request.updatedAt ?? request.createdAt
            : null,
      ),
      _StatusItem(
        label: 'Đã giải quyết',
        isActive:
            request.status == 'resolved' || request.status == 'closed',
        date: request.status == 'resolved' || request.status == 'closed'
            ? request.updatedAt ?? request.createdAt
            : null,
      ),
      _StatusItem(
        label: 'Đã đóng',
        isActive: request.status == 'closed',
        date: request.status == 'closed'
            ? request.updatedAt ?? request.createdAt
            : null,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            'Tiến trình giải quyết',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
          ),
          const SizedBox(height: 16),
          ...statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final isLast = index == statuses.length - 1;
            return _TimelineItem(
              status: status,
              isLast: isLast,
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _StatusItem {
  const _StatusItem({
    required this.label,
    required this.isActive,
    this.date,
  });

  final String label;
  final bool isActive;
  final DateTime? date;
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.status,
    required this.isLast,
  });

  final _StatusItem status;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: status.isActive
                    ? AppColors.orange600
                    : AppColors.gray300,
                border: Border.all(
                  color: status.isActive
                      ? AppColors.orange600
                      : AppColors.gray300,
                  width: 2,
                ),
              ),
              child: status.isActive
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: status.isActive
                    ? AppColors.orange600
                    : AppColors.gray300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: status.isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: status.isActive
                            ? AppColors.gray900
                            : AppColors.gray500,
                      ),
                ),
                if (status.isActive && status.date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.formatDateTime(status.date!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.gray500,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessagesCard extends StatelessWidget {
  const _MessagesCard({required this.messages});

  final List<SupportMessage> messages;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            'Lịch sử trao đổi',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray900,
                ),
          ),
          const SizedBox(height: 16),
          ...messages.map((message) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MessageBubble(
                message: message.message,
                isFromUser: message.isFromUser,
                time: DateFormatter.formatChatTime(message.createdAt),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.orderId,
    required this.orderSummary,
  });

  final int orderId;
  final OrderSummary orderSummary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                Icons.receipt_long,
                size: 20,
                color: AppColors.orange600,
              ),
              const SizedBox(width: 8),
              Text(
                'Mã đơn hàng #$orderId',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.orange600,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Sản phẩm',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray900,
                ),
          ),
          const SizedBox(height: 12),
          ...orderSummary.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.bookImageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.bookImageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.image_outlined,
                              color: AppColors.gray400,
                              size: 24,
                            ),
                          )
                        : const Icon(
                            Icons.image_outlined,
                            color: AppColors.gray400,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.bookTitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.bookAuthor.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            item.bookAuthor,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.gray600,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Số lượng: ${item.quantity}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.gray500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isFromUser,
    required this.time,
  });

  final String message;
  final bool isFromUser;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isFromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isFromUser ? AppColors.orange600 : AppColors.gray100,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isFromUser ? 16 : 4),
            bottomRight: Radius.circular(isFromUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isFromUser ? Colors.white : AppColors.gray900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isFromUser
                        ? Colors.white70
                        : AppColors.gray500,
                    fontSize: 10,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
