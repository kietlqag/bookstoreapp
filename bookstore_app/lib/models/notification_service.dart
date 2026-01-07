import 'dart:convert';
import 'dart:io';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.relatedId,
    this.updatedAt,
  });

  final int id;
  final int userId;
  final String type; // 'order', 'promotion', 'product', 'system'
  final String title;
  final String message;
  final bool isRead;
  final int? relatedId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  NotificationType get notificationType {
    switch (type) {
      case 'order':
        return NotificationType.order;
      case 'promotion':
        return NotificationType.promotion;
      case 'product':
        return NotificationType.product;
      default:
        return NotificationType.system;
    }
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      userId: json['userId'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool,
      relatedId: json['relatedId'] as int?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String).toLocal()
          : null,
    );
  }
}

enum NotificationType {
  order,
  promotion,
  product,
  system,
}

class NotificationService {
  NotificationService({
    required this.baseUrl,
    required this.token,
  });

  final String baseUrl;
  String token;

  void updateToken(String newToken) {
    token = newToken;
  }

  Future<List<NotificationItem>> getNotifications({bool includeRead = true}) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/notifications?includeRead=$includeRead');
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(body);
        throw NotificationException(
          errorData['message']?.toString() ?? 'Request failed.',
        );
      }

      if (body.isEmpty) {
        return [];
      }

      final data = jsonDecode(body);
      if (data is! List) {
        throw NotificationException('Invalid response format.');
      }

      return (data as List<dynamic>)
          .map((json) => NotificationItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } on SocketException {
      throw NotificationException('Không thể kết nối đến server.');
    } on FormatException {
      throw NotificationException('Định dạng phản hồi không hợp lệ.');
    } finally {
      client.close(force: true);
    }
  }

  Future<NotificationItem> getNotification(int id) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/notifications/$id');
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(body);
        throw NotificationException(
          errorData['message']?.toString() ?? 'Request failed.',
        );
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      return NotificationItem.fromJson(data);
    } on SocketException {
      throw NotificationException('Không thể kết nối đến server.');
    } on FormatException {
      throw NotificationException('Định dạng phản hồi không hợp lệ.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> markAsRead(int id) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/notifications/$id/read');
      final request = await client.putUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(body);
        throw NotificationException(
          errorData['message']?.toString() ?? 'Request failed.',
        );
      }
    } on SocketException {
      throw NotificationException('Không thể kết nối đến server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> markAllAsRead() async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/notifications/read-all');
      final request = await client.putUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(body);
        throw NotificationException(
          errorData['message']?.toString() ?? 'Request failed.',
        );
      }
    } on SocketException {
      throw NotificationException('Không thể kết nối đến server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> deleteNotification(int id) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/notifications/$id');
      final request = await client.deleteUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(body);
        throw NotificationException(
          errorData['message']?.toString() ?? 'Request failed.',
        );
      }
    } on SocketException {
      throw NotificationException('Không thể kết nối đến server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<int> getUnreadCount() async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/notifications/unread-count');
      final request = await client.getUrl(uri);
      request.headers.set('Authorization', 'Bearer $token');
      request.headers.contentType = ContentType.json;

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(body);
        throw NotificationException(
          errorData['message']?.toString() ?? 'Request failed.',
        );
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['count'] as int? ?? 0;
    } on SocketException {
      throw NotificationException('Không thể kết nối đến server.');
    } on FormatException {
      throw NotificationException('Định dạng phản hồi không hợp lệ.');
    } finally {
      client.close(force: true);
    }
  }
}

class NotificationException implements Exception {
  NotificationException(this.message);

  final String message;

  @override
  String toString() => message;
}
