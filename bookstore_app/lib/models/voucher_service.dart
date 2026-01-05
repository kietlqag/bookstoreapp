import 'dart:convert';
import 'dart:io';

import 'voucher.dart';

class VoucherService {
  VoucherService({required this.baseUrl});

  final String baseUrl;

  Future<List<Voucher>> fetchVouchers({
    String? type,
    bool activeOnly = true,
  }) async {
    final client = HttpClient();
    try {
      final query = <String, String>{};
      if (type != null && type.isNotEmpty) {
        query['type'] = type;
      }
      query['activeOnly'] = activeOnly ? 'true' : 'false';
      final uri = Uri.parse('$baseUrl/api/vouchers').replace(
        queryParameters: query.isEmpty ? null : query,
      );
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw VoucherException('Request failed.');
      }

      if (body.isEmpty) {
        return [];
      }

      final data = jsonDecode(body);
      if (data is! List) {
        throw VoucherException('Invalid response format.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(Voucher.fromJson)
          .toList();
    } on SocketException {
      throw VoucherException('Cannot connect to server.');
    } on FormatException {
      throw VoucherException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }
}

class VoucherException implements Exception {
  VoucherException(this.message);

  final String message;

  @override
  String toString() => message;
}
