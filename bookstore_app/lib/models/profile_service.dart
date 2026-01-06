import 'dart:convert';
import 'dart:io';

import 'profile_summary.dart';

class ProfileService {
  ProfileService({required this.baseUrl});

  final String baseUrl;

  Future<ProfileSummary> fetchProfileSummary(int userId) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/users/$userId/summary');
      final request = await client.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Request failed.');
      }
      if (body.isEmpty) {
        throw Exception('Empty response.');
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      return ProfileSummary.fromJson(data);
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } finally {
      client.close(force: true);
    }
  }

  Future<ProfileSummary> updateProfile({
    required int userId,
    required String fullName,
    required String email,
    required String phoneNumber,
    required String address,
    required String avatar,
  }) async {
    final data = await _sendJson('PUT', '/api/users/$userId', {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'avatar': avatar,
    });
    return ProfileSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<String?> requestEmailChange({
    required int userId,
    required String email,
  }) async {
    final data = await _sendJson('POST', '/api/users/$userId/email/request', {
      'email': email,
    });
    return (data as Map<String, dynamic>)['code']?.toString();
  }

  Future<ProfileSummary> verifyEmailChange({
    required int userId,
    required String email,
    required String code,
  }) async {
    final data = await _sendJson('POST', '/api/users/$userId/email/verify', {
      'email': email,
      'code': code,
    });
    return ProfileSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<String?> requestPhoneChange({
    required int userId,
    required String phoneNumber,
  }) async {
    final data = await _sendJson('POST', '/api/users/$userId/phone/request', {
      'phoneNumber': phoneNumber,
    });
    return (data as Map<String, dynamic>)['code']?.toString();
  }

  Future<ProfileSummary> verifyPhoneChange({
    required int userId,
    required String phoneNumber,
    required String code,
  }) async {
    final data = await _sendJson('POST', '/api/users/$userId/phone/verify', {
      'phoneNumber': phoneNumber,
      'code': code,
    });
    return ProfileSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<dynamic> _sendJson(
    String method,
    String path,
    Map<String, dynamic> payload,
  ) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.openUrl(method, uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String message = 'Request failed.';
        try {
          final parsed = jsonDecode(body);
          if (parsed is Map && parsed['message'] != null) {
            message = parsed['message'].toString();
          }
        } catch (_) {
          // ignore parse failure
        }
        throw Exception(message);
      }
      if (body.isEmpty) return null;
      return jsonDecode(body);
    } on SocketException {
      throw Exception('Cannot connect to server.');
    } finally {
      client.close(force: true);
    }
  }
}
