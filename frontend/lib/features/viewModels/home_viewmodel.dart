import 'package:flutter/material.dart';
import '../../../core/models/result_model.dart';
import '../../../core/services/result_service.dart';
import 'package:intl/intl.dart';

class ResultViewModel extends ChangeNotifier {
  final _service = ResultService();
  final Map<String, LotteryResult> _cache = {};

  LotteryResult? result;
  bool isLoading = false;
  String? error;
  bool notFound = false;

  DateTime currentDate = DateTime.now();

  /// Load toàn bộ data 1 lần, sau đó lookup local
  Future<void> load() async {
    isLoading = true;
    notifyListeners();

    try {
      final all = await _service.getAll();

      for (final item in all) {
        // Chỉ cache những record có provinces
        if (item.provinces.isNotEmpty) {
          final key = DateFormat('yyyy-MM-dd').format(item.date.toLocal());
          _cache[key] = item;
        }
      }

      // Hiển thị ngày gần nhất có dữ liệu
      _showClosestDate();
      error = null;
    } catch (e) {
      error = 'Không thể tải dữ liệu: $e';
    }
    await Future.delayed(const Duration(seconds: 1));
    isLoading = false;
    notifyListeners();
  }

  void _showClosestDate() {
    // Tìm ngày gần currentDate nhất trong cache
    final today = DateFormat('yyyy-MM-dd').format(currentDate);
    if (_cache.containsKey(today)) {
      result = _cache[today];
      return;
    }

    // Lấy ngày mới nhất trong cache
    if (_cache.isNotEmpty) {
      final sorted = _cache.keys.toList()..sort();
      final latest = sorted.last;
      currentDate = DateTime.parse(latest);
      result = _cache[latest];
    }
  }

  /// Lấy kết quả từ cache theo key ngày (yyyy-MM-dd), trả null nếu không có
  LotteryResult? getCache(String key) => _cache[key];

  void loadByDate(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);

    if (_cache.containsKey(key)) {
      currentDate = date;
      result = _cache[key];
      notFound = false;
    } else {
      notFound = true;
    }

    notifyListeners();
  }
}
