import 'dart:convert';
import 'dart:io';

import 'order.dart';

class OrderService {
  OrderService({required this.baseUrl});

  final String baseUrl;

  Future<int> createOrder({
    required int userId,
    int? serviceId,
    int? paymentId,
    String? shippingAddress,
    String? phoneNumber,
    String? note,
    String? status,
    required List<Map<String, dynamic>> items,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/orders');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'userId': userId,
        'serviceId': serviceId,
        'paymentId': paymentId,
        'shippingAddress': shippingAddress,
        'phoneNumber': phoneNumber,
        'note': note,
        'status': status,
        'orderItems': items,
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OrderServiceException('Request failed.');
      }
      if (body.isEmpty) {
        throw OrderServiceException('Empty response.');
      }
      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw OrderServiceException('Invalid response format.');
      }
      return data['id'] as int? ?? 0;
    } on SocketException {
      throw OrderServiceException('Cannot connect to server.');
    } on FormatException {
      throw OrderServiceException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }

  Future<List<OrderSummary>> fetchOrders(int userId) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/orders/users/$userId');
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OrderServiceException('Request failed.');
      }
      if (body.isEmpty) {
        return [];
      }
      final data = jsonDecode(body);
      if (data is! List) {
        throw OrderServiceException('Invalid response format.');
      }
      return data
          .whereType<Map<String, dynamic>>()
          .map(OrderSummary.fromJson)
          .toList();
    } on SocketException {
      throw OrderServiceException('Cannot connect to server.');
    } on FormatException {
      throw OrderServiceException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> updateOrderAddress({
    required int orderId,
    required int userId,
    String? shippingAddressNew,
    String? shippingAddressOld,
    String? recipientName,
    String? phoneNumber,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/orders/$orderId/address');
      final request = await client.patchUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'userId': userId,
        'shippingAddressNew': shippingAddressNew,
        'shippingAddressOld': shippingAddressOld,
        'recipientName': recipientName,
        'phoneNumber': phoneNumber,
      }));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OrderServiceException('Request failed.');
      }
    } on SocketException {
      throw OrderServiceException('Cannot connect to server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> cancelOrder({
    required int orderId,
    required int userId,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/orders/$orderId/status');
      final request = await client.patchUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'userId': userId,
        'status': 'cancelled',
      }));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OrderServiceException('Request failed.');
      }
    } on SocketException {
      throw OrderServiceException('Cannot connect to server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> markOrderDelivered({
    required int orderId,
    required int userId,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/orders/$orderId/status');
      final request = await client.patchUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'userId': userId,
        'status': 'delivered',
      }));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw OrderServiceException('Request failed.');
      }
    } on SocketException {
      throw OrderServiceException('Cannot connect to server.');
    } finally {
      client.close(force: true);
    }
  }
}

class OrderServiceException implements Exception {
  OrderServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
