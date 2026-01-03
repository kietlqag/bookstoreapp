import 'dart:convert';
import 'dart:io';

import 'category.dart';

class CategoryService {
  CategoryService({required this.baseUrl});

  final String baseUrl;

  Future<List<Category>> fetchCategories() async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/categories');
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CategoryException('Request failed.');
      }

      if (body.isEmpty) {
        return [];
      }

      final data = jsonDecode(body);
      if (data is! List) {
        throw CategoryException('Invalid response format.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(Category.fromJson)
          .toList();
    } on SocketException {
      throw CategoryException('Cannot connect to server.');
    } on FormatException {
      throw CategoryException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }
}

class CategoryException implements Exception {
  CategoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
