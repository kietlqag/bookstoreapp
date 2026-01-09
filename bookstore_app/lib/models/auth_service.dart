import 'dart:convert';
import 'dart:io';

import 'auth_session.dart';

class AuthService {
  AuthService({required this.baseUrl});

  final String baseUrl;

  Future<dynamic> login({required String email, required String password}) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/auth/login');
      print('🔗 Attempting login to: $uri');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'email': email,
        'password': password,
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(_extractMessage(body) ?? 'Authentication failed.');
      }

      if (body.isEmpty) {
        throw AuthException('Empty response from server.');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      
      // Check if 2FA is required
      if (data['requiresTwoFactor'] == true) {
        return {
          'requiresTwoFactor': true,
          'message': data['message']?.toString() ?? 'Mã OTP đã được gửi đến email của bạn.',
        };
      }

      // Normal login response
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

  Future<void> forgotPassword({required String email}) {
    return _postOk('/api/auth/forgot-password', {
      'email': email,
    });
  }

  Future<void> verifyResetOtp({
    required String email,
    required String code,
  }) {
    return _postOk('/api/auth/verify-reset-otp', {
      'email': email,
      'code': code,
    });
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) {
    return _postOk('/api/auth/reset-password', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  Future<AuthSession> verifyLoginOtp({
    required String email,
    required String code,
  }) {
    final payload = <String, dynamic>{
      'email': email,
      'code': code,
    };
    return _postAuth('/api/auth/verify-login-otp', payload);
  }

  Future<dynamic> socialRegister({
    required String provider,
    required String providerUserId,
    required String fullName,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/auth/social/register');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode({
        'provider': provider,
        'providerUserId': providerUserId,
        'fullName': fullName,
      }));

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AuthException(_extractMessage(body) ?? 'Authentication failed.');
      }

      if (body.isEmpty) {
        throw AuthException('Empty response from server.');
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      
      // Check if 2FA is required
      if (data['requiresTwoFactor'] == true) {
        return {
          'requiresTwoFactor': true,
          'email': data['email']?.toString() ?? '',
          'message': data['message']?.toString() ?? 'Mã OTP đã được gửi đến email của bạn.',
        };
      }

      // Normal login response
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

  Future<dynamic> socialLogin({
    required String provider,
    required String providerUserId,
    String? email,
  }) async {
    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/api/auth/social/login');
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType.json;
      final payload = <String, dynamic>{
        'provider': provider,
        'providerUserId': providerUserId,
      };
      if (email != null && email.trim().isNotEmpty) {
        payload['email'] = email.trim();
      }
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
      
      // Check if 2FA is required
      if (data['requiresTwoFactor'] == true) {
        return {
          'requiresTwoFactor': true,
          'email': data['email']?.toString() ?? '',
          'message': data['message']?.toString() ?? 'Mã OTP đã được gửi đến email của bạn.',
        };
      }

      // Normal login response
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

class TwoFactorRequiredException implements Exception {
  TwoFactorRequiredException({required this.email, required this.message});
  final String email;
  final String message;
  
  @override
  String toString() => message;
}

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
