import 'dart:convert';
import 'dart:io';

import 'shipping_method.dart';

class ShippingMethodService {
  ShippingMethodService({required this.baseUrl});

  final String baseUrl;

  Future<List<ShippingMethod>> fetchShippingMethods({
    bool activeOnly = true,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/shipping-methods').replace(
        queryParameters: {
          'activeOnly': activeOnly ? 'true' : 'false',
        },
      );
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ShippingMethodException('Request failed.');
      }

      if (body.isEmpty) {
        return [];
      }

      final data = jsonDecode(body);
      if (data is! List) {
        throw ShippingMethodException('Invalid response format.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(ShippingMethod.fromJson)
          .toList();
    } on SocketException {
      throw ShippingMethodException('Cannot connect to server.');
    } on FormatException {
      throw ShippingMethodException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }
}

class ShippingMethodException implements Exception {
  ShippingMethodException(this.message);

  final String message;

  @override
  String toString() => message;
}
