import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  static const String _key = 'recent_searches';
  static const int _maxItems = 50; // Tăng số lượng lưu trữ

  /// Load danh sách lịch sử tìm kiếm
  static Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  /// Thêm một từ khóa tìm kiếm vào lịch sử
  static Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();
    
    // Loại bỏ duplicate (case-insensitive)
    final normalizedQuery = _normalize(query.trim());
    history.removeWhere((item) => _normalize(item) == normalizedQuery);
    
    // Thêm vào đầu danh sách
    history.insert(0, query.trim());
    
    // Giới hạn số lượng
    if (history.length > _maxItems) {
      history.removeRange(_maxItems, history.length);
    }
    
    await prefs.setStringList(_key, history);
  }

  /// Xóa một từ khóa cụ thể khỏi lịch sử
  static Future<void> removeSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();
    history.removeWhere((item) => _normalize(item) == _normalize(query));
    await prefs.setStringList(_key, history);
  }

  /// Xóa toàn bộ lịch sử tìm kiếm
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Kiểm tra xem có lịch sử tìm kiếm không
  static Future<bool> hasHistory() async {
    final history = await getSearchHistory();
    return history.isNotEmpty;
  }

  /// Normalize chuỗi để so sánh (loại bỏ dấu, lowercase)
  static String _normalize(String input) {
    var output = input.toLowerCase();
    output = output.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    output = output.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    output = output.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    output = output.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    output = output.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    output = output.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    output = output.replaceAll(RegExp(r'đ'), 'd');
    output = output.replaceAll(RegExp(r'\s+'), ' ').trim();
    return output;
  }
}
