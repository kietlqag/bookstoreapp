import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

class SupportService {
  SupportService({required this.baseUrl});

  final String baseUrl;

  Future<int> submitSupportRequest({
    required int userId,
    required String subject,
    required String message,
    int? orderId,
    String? category,
    String? email,
    String? phone,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/support/requests');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'userId': userId,
        'orderId': orderId,
        'subject': subject,
        'message': message,
        'category': category,
        'email': email,
        'phone': phone,
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SupportException('Gửi yêu cầu hỗ trợ thất bại.');
      }
      
      if (body.isEmpty) {
        throw SupportException('Không có phản hồi từ server.');
      }
      
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw SupportException('Định dạng phản hồi không hợp lệ.');
      }
      
      return data['id'] as int? ?? 0;
    } on SocketException {
      throw SupportException('Không thể kết nối đến server.');
    } on FormatException {
      throw SupportException('Định dạng phản hồi không hợp lệ.');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<SupportMessage>> sendMessage({
    required int userId,
    required String message,
    int? requestId,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/support/messages');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'userId': userId,
        'message': message,
        'requestId': requestId,
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SupportException('Gửi tin nhắn thất bại.');
      }
      
      if (body.isEmpty) {
        return [];
      }
      
      final data = jsonDecode(body);
      if (data is! List) {
        throw SupportException('Định dạng phản hồi không hợp lệ.');
      }
      
      return data
          .whereType<Map<String, dynamic>>()
          .map(SupportMessage.fromJson)
          .toList();
    } on SocketException {
      throw SupportException('Không thể kết nối đến server.');
    } on FormatException {
      throw SupportException('Định dạng phản hồi không hợp lệ.');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<SupportMessage>> fetchMessages(int userId, {int? requestId}) async {
    final client = HttpClient();
    try {
      final queryParams = <String, String>{'userId': userId.toString()};
      if (requestId != null) {
        queryParams['requestId'] = requestId.toString();
      }
      final uri = Uri.parse('$baseUrl/api/support/messages').replace(
        queryParameters: queryParams,
      );
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SupportException('Tải tin nhắn thất bại.');
      }

      if (body.isEmpty) {
        return [];
      }

      final data = jsonDecode(body);
      if (data is! List) {
        throw SupportException('Định dạng phản hồi không hợp lệ.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(SupportMessage.fromJson)
          .toList();
    } on SocketException {
      throw SupportException('Không thể kết nối đến server.');
    } on FormatException {
      throw SupportException('Định dạng phản hồi không hợp lệ.');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<SupportRequest>> fetchRequests(int userId) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/support/requests').replace(
        queryParameters: {'userId': userId.toString()},
      );
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SupportException('Tải danh sách yêu cầu thất bại.');
      }

      if (body.isEmpty) {
        return [];
      }

      final data = jsonDecode(body);
      if (data is! List) {
        throw SupportException('Định dạng phản hồi không hợp lệ.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(SupportRequest.fromJson)
          .toList();
    } on SocketException {
      throw SupportException('Không thể kết nối đến server.');
    } on FormatException {
      throw SupportException('Định dạng phản hồi không hợp lệ.');
    } finally {
      client.close(force: true);
    }
  }

  Future<SupportRequestDetail> fetchRequestDetail(int requestId, int userId) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/support/requests/$requestId').replace(
        queryParameters: {'userId': userId.toString()},
      );
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SupportException('Tải chi tiết yêu cầu thất bại.');
      }

      if (body.isEmpty) {
        throw SupportException('Không có phản hồi từ server.');
      }

      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw SupportException('Định dạng phản hồi không hợp lệ.');
      }

      return SupportRequestDetail.fromJson(data);
    } on SocketException {
      throw SupportException('Không thể kết nối đến server.');
    } on FormatException {
      throw SupportException('Định dạng phản hồi không hợp lệ.');
    } finally {
      client.close(force: true);
    }
  }
}

class SupportRequest {
  SupportRequest({
    required this.id,
    required this.userId,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    this.orderId,
    this.category,
    this.email,
    this.phone,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final int? orderId;
  final String subject;
  final String message;
  final String? category;
  final String? email;
  final String? phone;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory SupportRequest.fromJson(Map<String, dynamic> json) {
    return SupportRequest(
      id: json['id'] as int,
      userId: json['userId'] as int,
      orderId: json['orderId'] as int?,
      subject: json['subject'] as String,
      message: json['message'] as String,
      category: json['category'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String).toLocal()
          : null,
    );
  }

  String get statusText {
    switch (status) {
      case 'pending':
        return 'Chờ xử lý';
      case 'in_progress':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã giải quyết';
      case 'closed':
        return 'Đã đóng';
      default:
        return status;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class SupportRequestDetail extends SupportRequest {
  SupportRequestDetail({
    required super.id,
    required super.userId,
    required super.subject,
    required super.message,
    required super.status,
    required super.createdAt,
    super.orderId,
    super.category,
    super.email,
    super.phone,
    super.updatedAt,
    required this.messages,
    this.orderSummary,
  });

  final List<SupportMessage> messages;
  final OrderSummary? orderSummary;

  factory SupportRequestDetail.fromJson(Map<String, dynamic> json) {
    final request = SupportRequest.fromJson(json);
    final messages = (json['messages'] as List<dynamic>?)
            ?.map((m) => SupportMessage.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];
    final orderSummaryJson = json['orderSummary'] as Map<String, dynamic>?;
    final orderSummary = orderSummaryJson != null
        ? OrderSummary.fromJson(orderSummaryJson)
        : null;
    return SupportRequestDetail(
      id: request.id,
      userId: request.userId,
      orderId: request.orderId,
      subject: request.subject,
      message: request.message,
      status: request.status,
      createdAt: request.createdAt,
      category: request.category,
      email: request.email,
      phone: request.phone,
      updatedAt: request.updatedAt,
      messages: messages,
      orderSummary: orderSummary,
    );
  }
}

class OrderSummary {
  OrderSummary({
    required this.id,
    required this.items,
  });

  final int id;
  final List<OrderItemSummary> items;

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>?)
            ?.map((item) => OrderItemSummary.fromJson(item as Map<String, dynamic>))
            .toList() ??
        [];
    return OrderSummary(
      id: json['id'] as int,
      items: items,
    );
  }
}

class OrderItemSummary {
  OrderItemSummary({
    required this.bookId,
    required this.quantity,
    required this.bookTitle,
    required this.bookImageUrl,
    required this.bookAuthor,
  });

  final int bookId;
  final int quantity;
  final String bookTitle;
  final String bookImageUrl;
  final String bookAuthor;

  factory OrderItemSummary.fromJson(Map<String, dynamic> json) {
    return OrderItemSummary(
      bookId: json['bookId'] as int,
      quantity: json['quantity'] as int? ?? 0,
      bookTitle: json['bookTitle']?.toString() ?? '',
      bookImageUrl: json['bookImageUrl']?.toString() ?? '',
      bookAuthor: json['bookAuthor']?.toString() ?? '',
    );
  }
}

class SupportMessage {
  SupportMessage({
    required this.id,
    required this.userId,
    required this.message,
    required this.isFromUser,
    required this.createdAt,
    this.requestId,
  });

  final int id;
  final int userId;
  final String message;
  final bool isFromUser;
  final DateTime createdAt;
  final int? requestId;

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as int,
      userId: json['userId'] as int,
      message: json['message'] as String,
      isFromUser: json['isFromUser'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      requestId: json['requestId'] as int?,
    );
  }
}

class SupportException implements Exception {
  SupportException(this.message);

  final String message;

  @override
  String toString() => message;
}
