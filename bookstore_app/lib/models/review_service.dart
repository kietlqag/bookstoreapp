import 'dart:convert';
import 'dart:io';

import 'review.dart';

class ReviewService {
  ReviewService({required this.baseUrl});

  final String baseUrl;

  Future<List<Review>> fetchReviews(int bookId) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/reviews?bookId=$bookId');
      final request = await client.getUrl(uri);
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ReviewException('Request failed.');
      }

      if (body.isEmpty) {
        return [];
      }

      final data = jsonDecode(body);
      if (data is! List) {
        throw ReviewException('Invalid response format.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(Review.fromJson)
          .toList();
    } on SocketException {
      throw ReviewException('Cannot connect to server.');
    } on FormatException {
      throw ReviewException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }
}

class ReviewException implements Exception {
  ReviewException(this.message);

  final String message;

  @override
  String toString() => message;
}
