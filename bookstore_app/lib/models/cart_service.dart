import 'dart:convert';
import 'dart:io';

import 'cart_item.dart';

class CartService {
  CartService({required this.baseUrl});

  final String baseUrl;

  Future<List<CartItem>> fetchCart(int userId) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/carts/users/$userId');
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CartException('Request failed.');
      }

      if (body.isEmpty) {
        return [];
      }

      final data = jsonDecode(body);
      if (data is! List) {
        throw CartException('Invalid response format.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(CartItem.fromJson)
          .toList();
    } on SocketException {
      throw CartException('Cannot connect to server.');
    } on FormatException {
      throw CartException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }

  Future<CartItem> addToCart({
    required int userId,
    required int bookId,
    required int quantity,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/carts');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'userId': userId,
          'bookId': bookId,
          'quantity': quantity,
        }),
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CartException('Request failed.');
      }

      if (body.isEmpty) {
        throw CartException('Empty response from server.');
      }

      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw CartException('Invalid response format.');
      }

      return CartItem.fromJson(data);
    } on SocketException {
      throw CartException('Cannot connect to server.');
    } on FormatException {
      throw CartException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }

  Future<CartItem?> updateQuantity({
    required int cartId,
    required int quantity,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/carts/$cartId');
      final request = await client.patchUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({'quantity': quantity}));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CartException('Request failed.');
      }

      if (body.isEmpty) {
        return null;
      }

      final data = jsonDecode(body);
      if (data is Map<String, dynamic> && data['removed'] == true) {
        return null;
      }

      if (data is! Map<String, dynamic>) {
        throw CartException('Invalid response format.');
      }

      return CartItem.fromJson(data);
    } on SocketException {
      throw CartException('Cannot connect to server.');
    } on FormatException {
      throw CartException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> removeItem(int cartId) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/carts/$cartId');
      final request = await client.deleteUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CartException('Request failed.');
      }
    } on SocketException {
      throw CartException('Cannot connect to server.');
    } finally {
      client.close(force: true);
    }
  }
}

class CartException implements Exception {
  CartException(this.message);

  final String message;

  @override
  String toString() => message;
}
