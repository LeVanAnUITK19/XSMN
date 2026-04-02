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

  Future<void> load() async {
    await loadByDate(currentDate);
  }

  Future<void> loadByDate(DateTime date) async {
    final formatted = DateFormat('yyyy-MM-dd').format(date);

    if (_cache.containsKey(formatted)) {
      currentDate = date;
      result = _cache[formatted];
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      currentDate = date;
      result = await _service.getOne(date: formatted, region: 'mien-nam');
      _cache[formatted] = result!;
      error = null;
      notFound = false;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('No data found')) {
        notFound = true;
        // giữ nguyên result cũ, chỉ báo không có dữ liệu
      } else {
        error = "Không thể tải dữ liệu: $msg";
      }
    }

    isLoading = false;
    notifyListeners();
  }
}
