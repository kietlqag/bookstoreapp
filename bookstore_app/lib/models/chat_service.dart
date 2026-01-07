import 'dart:convert';
import 'dart:io';

import 'book.dart';
import 'voucher.dart';

class ChatMessage {
  ChatMessage({
    required this.role,
    required this.content,
    this.timestamp,
    this.suggestedBooks,
    this.suggestedVouchers,
  });

  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime? timestamp;
  final List<Book>? suggestedBooks;
  final List<Voucher>? suggestedVouchers;

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
    };
  }
}

class ChatResponse {
  ChatResponse({
    required this.message,
    this.suggestedBooks,
    this.suggestedVouchers,
  });

  final String message;
  final List<Book>? suggestedBooks;
  final List<Voucher>? suggestedVouchers;

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    final books = json['suggestedBooks'] as List?;
    final vouchers = json['suggestedVouchers'] as List?;
    return ChatResponse(
      message: json['message'] as String? ?? '',
      suggestedBooks: books?.map((b) => Book.fromJson(b as Map<String, dynamic>)).toList(),
      suggestedVouchers: vouchers?.map((v) => Voucher.fromJson(v as Map<String, dynamic>)).toList(),
    );
  }
}

class ChatService {
  ChatService({required this.baseUrl});

  final String baseUrl;

  Future<ChatResponse> sendMessage(List<ChatMessage> messages) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/chat');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'messages': messages.map((m) => m.toJson()).toList(),
        }),
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorData = jsonDecode(body);
        throw ChatException(
          errorData['message']?.toString() ?? 'Request failed.',
        );
      }

      if (body.isEmpty) {
        throw ChatException('Empty response from server.');
      }

      final data = jsonDecode(body);
      if (data is! Map<String, dynamic>) {
        throw ChatException('Invalid response format.');
      }

      return ChatResponse.fromJson(data);
    } on SocketException {
      throw ChatException('Không thể kết nối đến server.');
    } on FormatException {
      throw ChatException('Định dạng phản hồi không hợp lệ.');
    } finally {
      client.close(force: true);
    }
  }
}

class ChatException implements Exception {
  ChatException(this.message);

  final String message;

  @override
  String toString() => message;
}
