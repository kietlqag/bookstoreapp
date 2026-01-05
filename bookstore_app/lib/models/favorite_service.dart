import 'dart:convert';
import 'dart:io';

class FavoriteService {
  FavoriteService({required this.baseUrl});

  final String baseUrl;

  Future<Set<int>> fetchFavoriteIds(int userId) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/favorites/$userId');
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Request failed.');
      }

      if (body.isEmpty) return <int>{};
      final data = jsonDecode(body) as List<dynamic>;
      return data.map((item) => int.tryParse(item.toString()) ?? 0)
          .where((id) => id > 0)
          .toSet();
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> addFavorite({
    required int userId,
    required int bookId,
  }) async {
    await _post('/api/favorites', {
      'userId': userId,
      'bookId': bookId,
    });
  }

  Future<void> removeFavorite({
    required int userId,
    required int bookId,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/favorites/$userId/$bookId');
      final request = await client.deleteUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Request failed.');
      }
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _post(String path, Map<String, dynamic> payload) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Request failed.');
      }
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } finally {
      client.close(force: true);
    }
  }
}
