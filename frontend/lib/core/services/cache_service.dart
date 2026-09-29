import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache đơn giản dùng SharedPreferences để lưu JSON response
/// Mục tiêu: app hiển thị data cũ ngay lập tức khi mở,
/// rồi fetch mới ở background → user không thấy màn loading trắng
class CacheService {
  static const _keyPrefix = 'xsmn_cache_';
  static const _keyTimestamp = 'xsmn_cache_ts_';

  // Lưu JSON string vào local cache với timestamp
  static Future<void> save(String key, String jsonData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix$key', jsonData);
    await prefs.setInt(
      '$_keyTimestamp$key',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  // Lấy JSON string từ cache — trả null nếu không có hoặc đã hết hạn
  static Future<String?> get(String key, {Duration maxAge = const Duration(hours: 6)}) async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('$_keyTimestamp$key');
    if (ts == null) return null;

    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > maxAge.inMilliseconds) return null;

    return prefs.getString('$_keyPrefix$key');
  }

  // Xóa cache theo key
  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$key');
    await prefs.remove('$_keyTimestamp$key');
  }
}
