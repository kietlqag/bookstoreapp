import 'dart:convert';
import 'dart:io';

import 'book.dart';

class BookService {
  BookService({required this.baseUrl});

  final String baseUrl;

  Future<List<Book>> fetchBooks() async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/books');
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BookException('Request failed.');
      }

      if (body.isEmpty) {
        return [];
      }

      final data = jsonDecode(body);
      if (data is! List) {
        throw BookException('Invalid response format.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(Book.fromJson)
          .toList();
    } on SocketException {
      throw BookException('Cannot connect to server.');
    } on FormatException {
      throw BookException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }

  Future<Book> fetchBook(int id) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/books/$id');
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw BookException('Request failed.');
      }

      if (body.isEmpty) {
        throw BookException('Empty response from server.');
      }

      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw BookException('Invalid response format.');
      }

      return Book.fromJson(data);
    } on SocketException {
      throw BookException('Cannot connect to server.');
    } on FormatException {
      throw BookException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }
}

class BookException implements Exception {
  BookException(this.message);

  final String message;

  @override
  String toString() => message;
}
