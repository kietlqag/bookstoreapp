import 'dart:convert';
import 'dart:io';

import 'payment_method.dart';

class PaymentMethodService {
  PaymentMethodService({required this.baseUrl});

  final String baseUrl;

  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/payments/methods');
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw PaymentMethodException('Request failed.');
      }

      if (body.isEmpty) {
        return [];
      }

      final data = jsonDecode(body);
      if (data is! List) {
        throw PaymentMethodException('Invalid response format.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(PaymentMethod.fromJson)
          .toList();
    } on SocketException {
      throw PaymentMethodException('Cannot connect to server.');
    } on FormatException {
      throw PaymentMethodException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }
}

class PaymentMethodException implements Exception {
  PaymentMethodException(this.message);

  final String message;

  @override
  String toString() => message;
}
