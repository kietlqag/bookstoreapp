import 'dart:convert';
import 'dart:io';

import 'flash_sale.dart';

class FlashSaleService {
  FlashSaleService({required this.baseUrl});

  final String baseUrl;

  Future<FlashSale?> getActiveFlashSale() async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/flash-sale/active');
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 404) {
        return null; // No active flash sale
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw FlashSaleException('Request failed.');
      }

      if (body.isEmpty) {
        return null;
      }

      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw FlashSaleException('Invalid response format.');
      }

      return FlashSale.fromJson(data);
    } on SocketException {
      throw FlashSaleException('Cannot connect to server.');
    } on FormatException {
      throw FlashSaleException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }
}

class FlashSaleException implements Exception {
  FlashSaleException(this.message);

  final String message;

  @override
  String toString() => message;
}
