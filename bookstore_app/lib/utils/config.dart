import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _prefKeyBaseUrl = 'api_base_url';
  static String? _cachedBaseUrl;

  /// Lấy base URL cho API
  /// 
  /// Ưu tiên:
  /// 1. URL từ SharedPreferences (nếu đã lưu)
  /// 2. Environment variable API_BASE_URL
  /// 3. Tự động detect dựa trên platform
  static Future<String> getBaseUrl() async {
    // Nếu đã cache, trả về luôn
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }

    // Kiểm tra SharedPreferences trước
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_prefKeyBaseUrl);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _cachedBaseUrl = savedUrl;
      return savedUrl;
    }

    // Kiểm tra environment variable
    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) {
      _cachedBaseUrl = overrideUrl;
      await prefs.setString(_prefKeyBaseUrl, overrideUrl);
      return overrideUrl;
    }

    // Tự động detect dựa trên platform
    String baseUrl;
    if (Platform.isAndroid) {
      // LDPlayer và nhiều Android emulator không dùng 10.0.2.2
      // Nên dùng IP WiFi thật của máy host: 10.90.222.178
      // Hoặc có thể thay đổi qua environment variable hoặc SharedPreferences
      baseUrl = 'http://10.90.222.178:8080';
    } else if (Platform.isIOS) {
      // iOS simulator: dùng localhost (emulator chạy trên cùng máy)
      // iOS device thật: cần IP thực của máy tính
      baseUrl = 'http://localhost:8080';
    } else {
      // Desktop/Web: dùng localhost
      baseUrl = 'http://localhost:8080';
    }

    _cachedBaseUrl = baseUrl;
    await prefs.setString(_prefKeyBaseUrl, baseUrl);
    return baseUrl;
  }

  /// Lấy base URL đồng bộ (không async)
  /// Sử dụng khi không thể dùng async
  static String getBaseUrlSync() {
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }

    const overrideUrl = String.fromEnvironment('API_BASE_URL');
    if (overrideUrl.isNotEmpty) {
      _cachedBaseUrl = overrideUrl;
      return overrideUrl;
    }

    if (Platform.isAndroid) {
      // LDPlayer và nhiều Android emulator không dùng 10.0.2.2
      // Nên dùng IP WiFi thật của máy host: 10.90.222.178
      return 'http://10.90.222.178:8080';
    }
    return 'http://localhost:8080';
  }

  /// Lưu base URL vào SharedPreferences
  /// Cho phép thay đổi URL trong runtime
  static Future<void> setBaseUrl(String url) async {
    _cachedBaseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyBaseUrl, url);
  }

  /// Xóa base URL đã lưu, reset về mặc định
  static Future<void> clearBaseUrl() async {
    _cachedBaseUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyBaseUrl);
  }

}
