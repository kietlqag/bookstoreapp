import 'dart:convert';
import 'dart:io';

import 'order_review.dart';
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

  Future<List<OrderReview>> fetchOrderReviews({
    required int orderId,
    required int userId,
  }) async {
    final client = HttpClient();
    try {
      final uri =
          Uri.parse('$baseUrl/api/reviews?orderId=$orderId&userId=$userId');
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
          .map(OrderReview.fromJson)
          .toList();
    } on SocketException {
      throw ReviewException('Cannot connect to server.');
    } on FormatException {
      throw ReviewException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }

  Future<int> submitReview({
    required int orderId,
    required int orderItemId,
    required int bookId,
    required int userId,
    required String userName,
    required int rating,
    required String comment,
    required bool anonymous,
    required List<String> images,
    required List<String> videos,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/reviews');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      final payload = jsonEncode({
        'orderId': orderId,
        'orderItemId': orderItemId,
        'bookId': bookId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'anonymous': anonymous,
        'images': images,
        'videos': videos,
      });
      request.write(payload);

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ReviewException('Request failed.');
      }

      if (body.isEmpty) {
        return 0;
      }

      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw ReviewException('Invalid response format.');
      }
      return data['remaining'] as int? ?? 0;
    } on SocketException {
      throw ReviewException('Cannot connect to server.');
    } on FormatException {
      throw ReviewException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> updateReview({
    required int reviewId,
    required int userId,
    required String userName,
    required int rating,
    required String comment,
    required bool anonymous,
    required List<String> images,
    required List<String> videos,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/reviews/$reviewId');
      final request = await client.putUrl(uri);
      request.headers.contentType = ContentType.json;
      final payload = jsonEncode({
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'anonymous': anonymous,
        'images': images,
        'videos': videos,
      });
      request.write(payload);

      final response = await request.close();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ReviewException('Request failed.');
      }
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
