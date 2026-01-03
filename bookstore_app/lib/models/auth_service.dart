import 'dart:convert';
import 'dart:io';

import 'auth_session.dart';

class AuthService {
  AuthService({required this.baseUrl});

  final String baseUrl;

  Future<AuthSession> login({required String email, required String password}) {
    return _postAuth('/api/auth/login', {
      'email': email,
      'password': password,
    });
  }

  Future<void> requestRegisterOtp({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _postOk('/api/auth/register', {
      'fullName': fullName,
      'email': email,
      'password': password,
    });
  }

  Future<AuthSession> verifyOtp({
    required String email,
    required String code,
  }) {
    return _postAuth('/api/auth/verify', {
      'email': email,
      'code': code,
    });
  }

  Future<void> resendOtp({required String email}) {
    return _postOk('/api/auth/resend', {
      'email': email,
    });
  }

  Future<AuthSession> socialRegister({
    required String provider,
    required String providerUserId,
    required String fullName,
  }) {
    final payload = <String, dynamic>{
      'provider': provider,
      'providerUserId': providerUserId,
      'fullName': fullName,
    };
    return _postAuth('/api/auth/social/register', payload);
  }

  Future<AuthSession> socialLogin({
    required String provider,
    required String providerUserId,
    String? email,
  }) {
    final payload = <String, dynamic>{
      'provider': provider,
      'providerUserId': providerUserId,
    };
    if (email != null && email.trim().isNotEmpty) {
      payload['email'] = email.trim();
    }
    return _postAuth('/api/auth/social/login', payload);
  }

  Future<AuthSession> _postAuth(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(_extractMessage(body) ?? 'Authentication failed.');
      }

      if (body.isEmpty) {
        throw AuthException('Empty response from server.');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      final session = AuthSession.fromJson(data);
      if (session.token.isEmpty || session.userId == 0) {
        throw AuthException('Invalid response from server.');
      }
      return session;
    } on SocketException {
      throw AuthException('Cannot connect to server.');
    } on FormatException {
      throw AuthException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _postOk(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(payload));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(_extractMessage(body) ?? 'Request failed.');
      }
    } on SocketException {
      throw AuthException('Cannot connect to server.');
    } on FormatException {
      throw AuthException('Invalid response format.');
    } finally {
      client.close(force: true);
    }
  }

  String? _extractMessage(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['message']?.toString();
    } catch (_) {
      return null;
    }
  }
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
